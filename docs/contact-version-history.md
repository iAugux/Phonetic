# Contact version history

Version History records the contact fields changed by Phonetic, so users can preview and restore selected values from an earlier version. It is a local change history rather than a full-address-book snapshot or backup/export mechanism.

## User behavior

- Additional Settings → Version History lists operations that actually changed contacts. Batch add, batch clear, single-contact edits, and restores each create one version.
- Version 0 means before the first recorded Phonetic change. Other versions represent the state after that operation; they do not describe changes made before history was introduced.
- A restore preview folds later operations backward to the selected version. It displays the current and proposed values for each affected field.
- Verified fields are selected by default. External changes, discontinuities between recorded operations, and uncertain interrupted writes require explicit selection and a replacement confirmation.
- Missing, inaccessible, or differently linked contact identities cannot be restored. Contacts are never recreated. A second live check skips fields that changed after the preview.
- Restoring appends a new version, including the values it replaced. Later versions are retained, so the restore itself can be undone.
- Cancelled, failed, and interrupted operations retain the writes that already happened. An operation that did not change any fields creates no version.

## Write and recovery contract

`ContactVersionStore` serializes operations. `ContactVersionSession` supports the synchronous Contacts enumeration callbacks, protects its state with a lock, and rejects writes after finalization. The engine retains its operation lease until the worker and history finalization have finished, including cooperative cancellation.

Before each write, the session compares live values with the fetched source values and creates a fresh mutable copy. Only changed fields are assigned. It then atomically persists a prepared journal event containing the old and intended values **before** executing the Contacts save. A failed journal write prevents the Contacts write.

After saving, the session reads the affected fields again and confirms the event. Recovery reconciles any prepared event left by termination: values still equal to the old value need no change record; values equal to the intended value are confirmed; other values remain uncertain and are never selected automatically. A history error stops processing. Pending records are reconciled before another operation can start; unreadable or unsupported pending journals block new edits. A preview fails if any history it needs is unreadable.

Version metadata is finalized last. Empty operations are removed. An empty directory left before manifest creation is safe to discard because no Contacts write could have started. Restore previews carry the current history head ID; applying an outdated preview is rejected.

There is no atomic transaction spanning the app's journal and Apple's Contacts database. The prepared-event protocol covers interruption between these writes. It cannot determine who made an identical value change, or prevent an external writer from racing inside Contacts' own read/save window. Such ambiguous recovered values require confirmation when detectable.

## Scope and storage

History tracks only fields Phonetic modifies. It uses the same unified contact identifiers as the existing processing and whitelist implementation. It is not an account, group-membership, linked-record, photo, or system address-book mirror. Changes made outside Phonetic are not captured as independent versions.

Text fields retain their exact before/after values. Social-profile and instant-message arrays use secure archives containing only that array field, preserving labels and multivalue identifiers. Unrelated contact properties are not archived.

History is stored in Application Support with file protection, excluded from device backups, and never uploaded. Contact fields can contain sensitive information. Deleting the app deletes this history. Cross-device restoration is not supported.

History has a 100 MB file-storage limit. The storage card shows its usage and percentage in one list row. Usage counts the greater of each file's logical and allocated size, including history metadata; filesystem directory overhead and temporary atomic-write files are not included. Before each Contacts write, the prepared event must fit the budget. File allocation is checked after persisting the intent, and an intent that does not fit is removed before Contacts is touched. Metadata finalization has reserved space. Temporary job metadata can use that headroom before reclamation; eviction is deferred until an actual contact change, so no-op operations keep older history.

When a contact write needs space, the oldest completed versions are removed automatically, aiming for 80% usage or lower when the incoming record needs more room. Already over-limit history is also maintained when loaded. Removal always advances a contiguous earliest restore boundary; it never removes individual middle versions or the active pending version. If even deleting completed history cannot fit the incoming change, that history is left intact and the operation stops with its successful writes retained. Recovery and cleanup metadata writes remain possible when over the limit. There is no manual cleanup screen.

The boundary is committed first, then old folders move atomically into a hidden discarded directory before deletion. Interrupted cleanup resumes from this boundary; partially deleted discarded folders are never decoded as live history. Newer logs stay intact, the boundary remains a restore target, and version numbers keep increasing even after all completed logs are removed. A stale preview targeting already removed history is rejected. A restore authorized before automatic cleanup uses its immutable, validated preview even if retention advances past its old target during that operation; the restore itself records a new retained version.

Idle file access is actor-serialized. During processing, only the active session's locked writer may request reclamation; idle store methods reject calls and finalization waits for the writer to finish. The callback uses immutable storage configuration, never the actor's mutable lifecycle state. Cleanup changes history files only, never Contacts.

## Validation

The native Swift Testing target uses an isolated in-memory contact source and temporary journal directories. Coverage includes durable intent ordering, disk failure, no-op edits, failed and partial writes, interrupted recovery, denied access, corrupt history, field and multivalue round trips, version folding, reversible restores, external conflicts, missing contacts, preview revalidation, stale history heads, and cancellation. Tests never modify the system address book.

Device testing with real contact accounts is still needed for provider-specific save normalization, linked-contact identity changes, limited-access changes, and background termination timing. Batch edits and restores reuse the existing iOS 26+ system continued-processing presentation; iOS 17–25 use foreground processing without that presentation. Single-contact saves use a local progress indicator and do not start the system presentation.
