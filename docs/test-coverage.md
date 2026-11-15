# App test coverage

Snapshot date: November 15, 2026. Coverage was measured during development,
before the public import, using the full `Phonetic` test scheme in Debug on an
iOS simulator with Xcode code coverage enabled. These figures describe the
imported application and test source; they are not CI results for the latest
public commit. Rerun the command below to measure the current checkout.

Batch tests inject a history store and processing manager. Production uses the
shared services and standard defaults; tests use isolated fixtures.

## Measured coverage

| Scope | Recorded line coverage |
| --- | ---: |
| App executable lines | 3,067 / 8,984 (34.14%) |
| Files under Models | 1,970 / 2,437 (80.84%) |
| ContactVersionStore.swift | 95.78% |
| AppState.swift | 86.45% |
| PhoneticContacts+Clean.swift | 100% |
| PhoneticContacts+QuickSearch.swift | 97.06% |
| PhoneticContacts.swift | 83.25% |
| ContactProcessingTask.swift | 63.64% |

The recorded run passed **105 test declarations in 11 suites**.
Parameterized declarations exercise additional input combinations. These are
line-coverage measurements, not branch coverage or a percentage of user journeys
verified. SwiftUI generated closures contribute to executable-line totals;
hosting a view also does not prove its controls or transitions work correctly.

## Covered behavior

The existing suite covers version journaling and recovery, retention limits,
restore conflicts and unavailable contacts, stale previews, write failures,
cancellation, and background-task ordering through injected clients. It also
covers migration, whitelist display/search, pinyin preferences and formatting,
and home layout geometry at different sizes.

`PhoneticContacts+Whitelist.swift`, `SettingsMigration.swift`, and `AppBadge.swift`
retain 100% executable-line coverage. That does not establish exhaustive behavior
coverage, particularly across framework callbacks and settings combinations.

Regression tests cover the following contracts:

- Manual editor saves create history for each changed field while preserving
  unrelated values. Stale snapshots, foreign sessions, and closed sessions are
  rejected without writing contacts.
- Both supported URL and shortcut actions clear modal state and wait for actual
  dismissal before requesting access. Denied access starts no work; unknown
  shortcuts leave presentation state unchanged.
- Whitelist brief values come from the requested field, including an empty
  field; unsupported field keys are rejected.
- Invalid quick-search destinations preserve existing contact text even with
  overwriting enabled.
- Clear-field confirmation text lists exactly the selected optional fields,
  including none, every individual field, and all fields, in display order.

Batch integration coverage includes 12 declarations exercising complete engine entry points:

- Add pinyin for Chinese names and company-only contacts, skip whitelist, Latin,
  and empty contacts, and avoid creating a second version for unchanged results.
- Clear Chinese phonetics and selected optional fields while preserving Latin
  phonetics, unselected fields, and all whitelist values.
- Stop on enumeration or write failures, including errors after a write actually
  persisted; history retains the exact set of changed contacts.
- Complete empty batches and reject unavailable/busy history before enumeration.
- Cancel before work starts and during an in-flight save, then verify stopped
  history and that later operations can start normally. Reject overlapping work
  even after the processing flag is cleared during cancellation.
- Count skipped contacts in native progress and deliver ordered updates before
  completion, using a fake scheduler without OS submissions.
- Exercise editor save and selective restore through the engine, including
  recorded versions, preservation of unselected fields, and restore progress.

Tests use isolated defaults suites, temporary history fixtures, and fake contact
sources. They do not edit system contacts or submit real background jobs.

## Remaining gaps and priorities

| Priority | Area | Missing evidence and appropriate next step |
| --- | --- | --- |
| Medium | Batch failure combinations | The main add/clear entry points now run against real temporary history storage and fake contacts. Remaining combinations include history-finalization failure through the engine, changing preferences during a running batch, and native application-state transitions. Line execution alone does not establish every branch. |
| High | Contacts authorization and system changes | Verify real authorization transitions, limited access, and changes made outside the app through controlled integration tests. Injected permission and contact-source tests cannot validate framework delivery or access behavior. |
| High | Native continued processing | Fake-client tests cover ordering and cancellation, but the real system client remains unexecuted. Validate iOS 26 submission, iOS 27 asynchronous submission results, expiration, and delayed system launch on supported devices. Unit tests should not submit real OS tasks. |
| Medium | Restore and editor interaction | `ContactVersionsView.swift` and `EditableContactView.swift` have no executed lines in this run. Engine/store tests now cover save and selective restore, but do not establish selection controls, empty/conflicting restore presentation, retry, post-restore UI refresh, or editor save/error presentation. |
| Medium | Settings, onboarding, and reactive examples | `AdditionalSettingsView.swift` and `WalkthroughView.swift` have no executed lines. Verify setting changes propagate to the example and subsequent processing, permission navigation, and preservation of selections. Prefer observable behavior over merely instantiating each view. |
| Medium | Polyphonic correction settings | The correction path still depends on global polyphonic settings. Isolate that dependency before adding cases for enabled/disabled characters and compound surnames without mutating shared defaults. |
| Medium | Loading, animation, and accessibility | `DelayedProgressView.swift` has no executed lines. Verify fast completion, delayed appearance, cancellation, and reentry. Existing layout tests do not establish VoiceOver order, focus, Reduce Motion behavior, or smooth visual transitions; use targeted UI/device checks. |

Uncovered localizable titles, framework adapters, and view declarations should not
be exercised solely to increase the aggregate number. The next useful investment
is UI contracts and system integration, rather than repeating already covered
formatting combinations or raising the overall percentage with view construction.

## Reproducing the measurement

Use an available concrete iOS Simulator destination:

```sh
xcodebuild -project Phonetic.xcodeproj -scheme Phonetic \
  -configuration Debug -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' \
  -parallel-testing-enabled NO -enableCodeCoverage YES \
  -resultBundlePath /tmp/Phonetic-coverage.xcresult \
  CODE_SIGNING_ALLOWED=NO SWIFT_EMIT_LOC_STRINGS=NO test
xcrun xccov view --report /tmp/Phonetic-coverage.xcresult
```

Use a fresh result-bundle path for each run. Result bundles are generated locally
and are not committed. Retain the bundle from a new run when comparing coverage
across revisions; the historical snapshot above is a reference, not a substitute
for validating the current checkout.
