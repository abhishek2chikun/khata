# Task 05: Implement Encrypted Google Drive Backup And Restore

## Outcome

Turn the existing backup skeleton into a user-configurable encrypted Google Drive workflow with foreground backup/restore, best-effort daily scheduling near 02:00, catch-up, verified uploads, and 30-backup retention.

## Why This Task Exists

Local SQLite is the production target, so recoverability is a core data-safety requirement. A UI that merely claims cloud backup without OAuth/upload/background proof is unacceptable.

## Dependencies

Task 01 feasibility go and Task 02 backup schema 10. May run parallel with Tasks 04/06.

## Repository Evidence

- `backup/local_backup_service.dart`: encrypted package export/import and replacement semantics.
- `backup/local_backup_transfer_service.dart`: manual file transfer.
- `backup/drive_backup_service.dart`: skeleton interface.
- `backup/backup_scheduler.dart`: due/catch-up logic and unsupported adapter.
- `backup/backup_screen.dart`: manual UI and cloud-not-configured card.
- `app/app_dependencies.dart`, `main.dart`: local composition/startup scheduling hooks.
- Existing backup crypto, scheduler, screen, local-service, and transfer tests.

## Read Before Editing

- Design Google Drive Backup, Security, Failure, Observability, and Compatibility sections.
- Task 01 package/API proof notes.
- WorkManager and Google sign-in official setup docs for the resolved versions.

## Scope

### Change

- Introduce repository interfaces for Google account auth, Drive gateway, backup secret store, and background scheduler so tests use fakes.
- Implement Google account connect/disconnect and request the minimum approved Drive scope.
- Create/find one visible folder named `Khata Backups`; tag the folder/files with app properties so pruning never touches unrelated files with the same name.
- Backup flow:
  1. require connected account and secure password;
  2. export encrypted schema-10 package;
  3. compute SHA-256 and upload uniquely named `.khata` file;
  4. set app properties/description with schema, compatibility, timestamp, hash;
  5. fetch uploaded metadata and download/hash content or use a reliable media verification path;
  6. only then record success/update last backup;
  7. list app-owned backups newest-first and delete files after the newest 30.
- Restore flow lists backups newest-first with timestamp/size/schema, requires destructive confirmation and password, downloads, validates/decrypts fully, imports through `LocalBackupService`, clears session/logs out, and restarts dependency state as existing restore flow requires.
- Secure password setup requires entry/confirmation, at least eight characters, stores only in `flutter_secure_storage`, supports change/remove, and warns that a fresh install requires manual re-entry.
- Implement WorkManager adapter/callback:
  - unique periodic work with connected-network constraint;
  - initial delay to next local 02:00 and plugin-supported interval;
  - exponential/linear backoff as supported;
  - background callback constructs database, backup service, secure store, auth/Drive gateway and closes resources;
  - no foreground prompts; auth/secret missing records action-required failure;
  - startup catch-up remains and does not duplicate a successful run for the same due date.
- Replace cloud-not-configured card with account, automatic toggle, 02:00 schedule, last success/failure, Back up now, restore list, and clear action-required messages.
- Preserve manual export/import buttons.

### Preserve

- AES-256-GCM/PBKDF2 package format, version validation, no-session backup, and transactional restore replacement.
- Manual file backup path.

### Explicitly Out Of Scope

- Unencrypted Drive files, hidden appDataFolder, arbitrary selected folders, iOS background execution, account-wide file deletion, exact alarms.

## Contracts And Invariants

- `last_backup_at` changes only after verified successful upload.
- Retention deletes only files carrying Khata app ownership properties in the resolved Khata folder.
- Upload verification must precede pruning.
- Password/tokens/payload contents never enter backup events or logs.
- Wrong password, corrupt package, unsupported schema, canceled picker/confirmation, or download failure leaves local DB untouched.
- WorkManager and startup catch-up use a common idempotent due-run coordinator.

## Implementation Guidance

- Split pure orchestration from package adapters. Test orchestration with an in-memory fake Drive gateway.
- Use `extension_google_sign_in_as_googleapis_auth` to create an authenticated client for `googleapis/drive/v3.dart`; dispose clients.
- Store Drive file ID, not local temp path, in Drive backup event metadata where useful.
- Use application support/temp directories and delete temporary backup/download files in `finally`.
- Ensure background isolate initializes plugins as required by WorkManager/Flutter version.
- Keep OAuth setup docs generic with placeholders and `.gitignore` safeguards; do not add `google-services.json` unless the chosen official setup truly requires a user-supplied untracked file.

## Test-First Specification

- Fake Drive tests: folder create/reuse, upload metadata/hash, verification failure prevents success/prune, retention 31->30, unrelated files preserved, list order, download/restore, sign-in cancellation, auth expiry, network failure/retry.
- Secure-store tests: set/change/remove, no plaintext settings/database storage.
- Scheduler tests: next 02:00 delay, unique registration, disabled cancellation, missed-run catch-up, no duplicate after success, action-required behavior.
- Round-trip digest fixture: seed every backed-up table, export, mutate/delete data, restore, compare canonical sorted digest; sessions absent; wrong password digest unchanged.
- Screen tests for connect, password setup, enable/disable, Back up now, restore confirmation, status/error states, and manual controls retained.

## Validation Ladder

```bash
(cd mobile && flutter test test/backup)
(cd mobile && flutter test test/app/app_dependencies_test.dart test/app/local_mode_app_test.dart test/backup/backup_screen_test.dart)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --debug --dart-define=DATA_MODE=local)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
```

Configured physical-device evidence is mandatory for AC10/AC11: sign in, foreground backup, folder/file visible, retention behavior using test files, background registration/catch-up, wrong-password no-change proof, successful restore, logout, restart persistence.

## Review Checklist

- [ ] Minimum Drive scope and no secrets.
- [ ] Verified upload before success/prune.
- [ ] Only app-owned files pruned.
- [ ] Password only in secure storage.
- [ ] Background task has no UI dependency.
- [ ] Restore validates before replacement.
- [ ] Manual backup preserved.

## Allowed Adaptation

Exact WorkManager timing APIs may follow the resolved package. If periodic work cannot align exactly to 02:00, retain best-effort initial delay plus startup catch-up and document observed behavior. Do not switch storage model or encryption policy.

## Stop And Escalate If

- OAuth cannot be configured without changing the unresolved permanent app ID in this cycle.
- Background Google authorization cannot refresh without foreground interaction.
- Verification requires downloading prohibitively large content and no trustworthy alternative exists.
- Physical-device credentials/configuration are unavailable: implementation/tests may complete, but AC10/AC11 must remain unproven and Stage 2/5 must see the blocker.

## Commit Checkpoint

`feat(backup): add encrypted google drive recovery`

## Done When

Automated adapter/orchestration/digest tests pass, debug/release builds succeed, and configured device evidence is either complete or explicitly blocked without false production claims.

## Handoff Update

Record scopes, package versions, OAuth setup, Drive folder/file IDs redacted as needed, event samples, scheduler timing, retention proof, digest hashes, device/account environment, and remaining blocker.
