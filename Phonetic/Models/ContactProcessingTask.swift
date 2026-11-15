import BackgroundTasks
import Foundation
import OSLog

enum ContactProcessingOperation {
    case addPinyin, clearFields, editContact, restore

    var title: String {
        switch self {
        case .addPinyin: String(localized: "Adding Pinyin")
        case .clearFields: String(localized: "Clearing Contact Fields")
        case .editContact: String(localized: "Saving Contact")
        case .restore: String(localized: "Restoring Contact Fields")
        }
    }
}

@MainActor
protocol ContinuedProcessingClient: AnyObject {
    func prepare(onLaunch: @escaping @MainActor (String) -> Void, onExpiration: @escaping @MainActor (String) -> Void) -> Bool
    func submit(id: String, title: String, subtitle: String) async throws
    func update(id: String, checked: Int64, total: Int64, title: String, subtitle: String)
    func complete(id: String, success: Bool)
    func cancelRequest(id: String)
}

@MainActor
final class ContactProcessingTask {
    static let identifierPrefix = "com.iAugus.Phonetic.contactProcessing"
    static let shared: ContactProcessingTask = if #available(iOS 26.0, *) {
        ContactProcessingTask(client: SystemContinuedProcessingClient())
    } else {
        ContactProcessingTask(client: nil)
    }

    @MainActor
    private final class Job {
        let id: String
        let operation: ContactProcessingOperation
        let onCancel: @MainActor () -> Void
        let work: @MainActor () async -> ContactOperationOutcome
        let onSystemTaskAttached: @MainActor () -> Void
        let completion: CheckedContinuation<ContactOperationOutcome, Never>
        var worker: Task<Void, Never>?
        var started = false
        var usesSystemTask = false
        var cancelled = false
        var requestCancelled = false
        var subtitle = String(localized: "Preparing Contacts")
        var checked: Int64 = 0
        var total: Int64 = 1

        init(id: String, operation: ContactProcessingOperation, onCancel: @escaping @MainActor () -> Void, onSystemTaskAttached: @escaping @MainActor () -> Void, work: @escaping @MainActor () async -> ContactOperationOutcome, completion: CheckedContinuation<ContactOperationOutcome, Never>) {
            self.id = id
            self.operation = operation
            self.onCancel = onCancel
            self.onSystemTaskAttached = onSystemTaskAttached
            self.work = work
            self.completion = completion
        }
    }

    private let client: (any ContinuedProcessingClient)?
    private var prepared = false
    private var job: Job?
    private var finishedJobs: [String: (outcome: ContactOperationOutcome, operation: ContactProcessingOperation, checked: Int64, total: Int64)] = [:]
    private var finishedIDs: [String] = []
    private let logger = Logger(subsystem: "com.iAugus.Phonetic", category: "ContactProcessingTask")

    var isUsingSystemTask: Bool {
        job?.usesSystemTask == true
    }

    init(client: (any ContinuedProcessingClient)?) {
        self.client = client
        prepared = client?.prepare(onLaunch: { [weak self] in self?.launch(id: $0) }, onExpiration: { [weak self] in self?.cancel(id: $0) }) ?? false
    }

    func run(operation: ContactProcessingOperation, onCancel: @escaping @MainActor () -> Void, onSystemTaskAttached: @escaping @MainActor () -> Void = {}, work: @escaping @MainActor () async -> ContactOperationOutcome) async -> ContactOperationOutcome {
        guard !Task.isCancelled else { onCancel(); return .stopped }
        guard job == nil else { return .failed(.busy) }
        let id = "\(Self.identifierPrefix).\(UUID().uuidString)"
        return await withTaskCancellationHandler {
            await withCheckedContinuation { completion in
                let current = Job(id: id, operation: operation, onCancel: onCancel, onSystemTaskAttached: onSystemTaskAttached, work: work, completion: completion)
                job = current
                startWork(current)
                if prepared, let client { submit(current, client: client) }
            }
        } onCancel: {
            Task { @MainActor in self.cancel(id: id) }
        }
    }

    private func submit(_ current: Job, client: any ContinuedProcessingClient) {
        let id = current.id, title = current.operation.title
        let logger = logger
        // Submission is auxiliary and may finish after work. Capture no job/contact data across this await.
        Task { [weak self] in
            guard self?.job?.id == id, self?.job?.cancelled == false else { return }
            do {
                try await client.submit(id: id, title: title, subtitle: String(localized: "Preparing Contacts"))
            } catch {
                logger.info("Continued processing unavailable: \(error.localizedDescription)")
            }
            // The system can accept the request after an earlier cancellation; cancel it again then.
            guard let self, let job = self.job, job.id == id, !job.cancelled else {
                client.cancelRequest(id: id)
                return
            }
        }
    }

    func update(checked: Int, total: Int) {
        guard let job, !job.cancelled else { return }
        job.checked = max(job.checked, Int64(max(0, checked)))
        job.total = max(job.checked, Int64(max(1, total)))
        job.subtitle = String(localized: "Contacts checked: \(job.checked) / \(total)")
        guard job.usesSystemTask else { return }
        client?.update(id: job.id, checked: job.checked, total: job.total, title: job.operation.title,
                       subtitle: job.subtitle)
    }

    func cancel() {
        guard let job else { return }
        cancel(id: job.id)
    }

    private func launch(id: String) {
        guard let job, job.id == id else {
            // Late launches never restart work. Preserve a bounded set of recent completion results.
            if let finished = finishedJobs[id] {
                client?.update(id: id, checked: finished.outcome.succeeded ? finished.total : finished.checked,
                               total: finished.total, title: finished.operation.title, subtitle: finished.outcome.status)
                client?.complete(id: id, success: finished.outcome.succeeded)
            } else {
                client?.complete(id: id, success: false)
            }
            return
        }
        guard !job.usesSystemTask else { return }
        // Cancelled work may still be writing contacts or finalizing history. Keep the native task until finish.
        job.usesSystemTask = true
        client?.update(id: id, checked: job.checked, total: job.total, title: job.operation.title, subtitle: job.subtitle)
        job.onSystemTaskAttached()
    }

    private func startWork(_ current: Job) {
        current.worker = Task {
            guard job?.id == current.id, !current.cancelled, !Task.isCancelled else {
                finish(id: current.id, outcome: .stopped)
                return
            }
            current.started = true
            let outcome = await current.work()
            finish(id: current.id, outcome: outcome)
        }
    }

    private func cancelRequest(_ current: Job) {
        guard prepared, !current.requestCancelled else { return }
        current.requestCancelled = true
        client?.cancelRequest(id: current.id)
    }

    private func cancel(id: String) {
        guard let job, job.id == id, !job.cancelled else { return }
        job.cancelled = true
        job.onCancel()
        cancelRequest(job)
        job.worker?.cancel()
        if !job.started {
            finish(id: id, outcome: .stopped)
        }
        // Running contact writes stop cooperatively before the system task is completed.
    }

    private func finish(id: String, outcome: ContactOperationOutcome) {
        guard let current = job, current.id == id else { return }
        job = nil
        let outcome = current.cancelled && outcome.succeeded ? ContactOperationOutcome.stopped : outcome
        if prepared {
            finishedJobs[id] = (outcome, current.operation, current.checked, current.total)
            finishedIDs.append(id)
            if finishedIDs.count > 32 { finishedJobs.removeValue(forKey: finishedIDs.removeFirst()) }
        }
        cancelRequest(current)
        if current.usesSystemTask {
            client?.update(id: id, checked: outcome.succeeded ? current.total : current.checked, total: current.total,
                           title: current.operation.title, subtitle: outcome.status)
            client?.complete(id: id, success: outcome.succeeded)
        }
        current.completion.resume(returning: outcome)
    }
}

@available(iOS 26.0, *)
@MainActor
private final class SystemContinuedProcessingClient: ContinuedProcessingClient {
    private enum ClientError: Error { case registrationFailed }
    private var tasks: [String: BGContinuedProcessingTask] = [:]
    private var onLaunch: (@MainActor (String) -> Void)?
    private var onExpiration: (@MainActor (String) -> Void)?

    func prepare(onLaunch: @escaping @MainActor (String) -> Void, onExpiration: @escaping @MainActor (String) -> Void) -> Bool {
        self.onLaunch = onLaunch
        self.onExpiration = onExpiration
        return true
    }

    func submit(id: String, title: String, subtitle: String) async throws {
        guard let onLaunch, let onExpiration else { throw ClientError.registrationFailed }
        // Info.plist permits a wildcard, but each launch handler must use the full request ID.
        // Continued-processing handlers may be registered dynamically after app launch.
        // The scheduler invokes this handler on the specified main queue; task handles stay on MainActor.
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: id, using: .main) { [weak self] task in
            MainActor.assumeIsolated {
                guard let self, let task = task as? BGContinuedProcessingTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                let id = task.identifier
                self.tasks[id] = task
                task.progress.totalUnitCount = 1
                task.expirationHandler = { [weak self] in
                    Task { @MainActor in
                        guard self?.tasks[id] != nil else { return }
                        onExpiration(id)
                    }
                }
                onLaunch(id)
            }
        }
        guard registered else { throw ClientError.registrationFailed }
        try await Self.submitRequest(id: id, title: title, subtitle: subtitle)
    }

    @concurrent nonisolated private static func submitRequest(id: String, title: String, subtitle: String) async throws {
        let request = BGContinuedProcessingTaskRequest(identifier: id, title: title, subtitle: subtitle)
        // The scheduler submission may block. Construct and submit the request off the main actor.
        request.strategy = .fail
        if #available(iOS 27.0, *) {
            try await BGTaskScheduler.shared.submitTaskRequest(request)
        } else {
            try BGTaskScheduler.shared.submit(request)
        }
    }

    func update(id: String, checked: Int64, total: Int64, title: String, subtitle: String) {
        guard let task = tasks[id] else { return }
        task.progress.totalUnitCount = total
        task.progress.completedUnitCount = checked
        task.updateTitle(title, subtitle: subtitle)
    }

    func complete(id: String, success: Bool) {
        tasks.removeValue(forKey: id)?.setTaskCompleted(success: success)
    }

    func cancelRequest(id: String) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: id)
    }
}
