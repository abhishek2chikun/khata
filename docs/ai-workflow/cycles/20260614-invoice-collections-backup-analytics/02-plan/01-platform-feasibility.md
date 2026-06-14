# Task 01: Prove Platform Feasibility And Freeze Dependencies

## Outcome

Prove that the selected Flutter packages can support Google Drive authentication, Drive v3 transport, secure password retrieval, Android background execution, and charts in this checkout without committing secrets. Produce a go/no-go record before schema or feature implementation begins.

## Why This Task Exists

Drive backup is the least reversible and most environment-dependent part of the cycle. The SLM must discover package/API incompatibility before migrations and UI work accumulate around an unusable design.

## Dependencies

None. Start from baseline and cycle docs only.

## Repository Evidence

- `mobile/pubspec.yaml`: no Google, WorkManager, HTTP auth adapter, or chart dependency.
- `mobile/android/app/build.gradle.kts`: Java 17, Flutter-derived min/target SDK, example application ID.
- `mobile/android/app/src/main/AndroidManifest.xml`: no background/network declarations beyond the base app.
- `mobile/lib/backup/drive_backup_service.dart`: Drive interface plus configuration-error skeleton.
- `mobile/lib/backup/backup_scheduler.dart`: platform adapter abstraction and catch-up logic.
- `mobile/lib/app/app_dependencies.dart`: local dependency composition point.

## Read Before Editing

- `../02-design.md`: Google Drive Backup, Security, Failure, and Non-Goals sections.
- `mobile/agent.md`: secrets and local-mode constraints.
- Official package setup docs for `google_sign_in`, `googleapis`, `extension_google_sign_in_as_googleapis_auth`, `workmanager`, and `fl_chart` as resolved on implementation day.

## Scope

### Change

- On a temporary proof branch state within the canonical worktree, add the selected package families using versions compatible with the current SDK; commit the final dependency choices only after proof.
- Create test-only or isolated adapter spikes proving:
  - a `google_sign_in` account can provide an authenticated Google API client for Drive v3;
  - Drive folder/file list/upload/download/delete methods can be wrapped behind repository-owned interfaces;
  - `workmanager` can register a unique Android task and invoke a top-level callback dispatcher;
  - callback initialization can open local dependencies without widget state;
  - `flutter_secure_storage` can be accessed through a repository-owned backup-secret store;
  - `fl_chart` compiles under the current Flutter version.
- Record required external Google Cloud steps in the implementation log: Drive API enabled, Android OAuth client, package name/signing SHA fingerprints, consent screen/test user. Do not add credentials.

### Preserve

- Existing app ID/signing remain unchanged.
- Manual backup remains operational.
- No schema or business behavior changes in this task.

### Explicitly Out Of Scope

- Real upload/restore UI, retention, migrations, analytics UI, or production OAuth configuration.

## Contracts And Invariants

- Repository code owns interfaces; package-specific types do not leak into invoice/database domains.
- Background callback must be top-level/entry-point annotated as required by the plugin.
- A background task cannot prompt for sign-in or password. Missing auth/secret returns a retry or recorded foreground-action-required result.
- No token, client secret, SHA credential file, or backup password enters git or logs.

## Implementation Guidance

- Prefer package additions via `flutter pub add` and inspect the resulting lockfile; do not hand-pick incompatible transitive versions.
- Keep proof adapters minimal and injectable. If proof code is not part of the final architecture, remove it after capturing tests/evidence.
- Define future-owned abstractions in the plan/log, not production code, unless needed to compile a focused test.
- Confirm Android minimum SDK and manifest requirements before accepting the dependency set.

## Test-First Specification

- Add a focused test that fails because the existing `UnsupportedBackupScheduleAdapter` cannot register work.
- Add adapter tests with fake authenticated client/Drive gateway proving method signatures and error mapping.
- Add a callback initialization test that injects fake dependencies and completes without Flutter widget bindings.
- The expected pre-change signal is unsupported scheduling/configuration errors, not a passing fake that bypasses the real boundary.

## Validation Ladder

```bash
(cd mobile && flutter pub get)
(cd mobile && flutter test test/backup/backup_scheduler_test.dart)
(cd mobile && flutter test <new platform adapter tests>)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --debug --dart-define=DATA_MODE=local)
```

Required evidence: resolved versions, Android requirements, callback compilation, adapter tests, and debug APK build. Runtime OAuth is optional at this gate if external configuration is unavailable, but the exact external blocker must be recorded.

## Review Checklist

- [ ] Official/supported package families used.
- [ ] No secrets or credential files added.
- [ ] Background code has no UI dependency.
- [ ] External configuration checklist is exact.
- [ ] Dependency lockfile is intentional.

## Allowed Adaptation

Version numbers and minor adapter method names may follow current package APIs. Do not replace package families or visible-folder Drive behavior without returning to Stage 2.

## Stop And Escalate If

- Google auth requires committing a secret.
- Package SDK requirements exceed the current project without an approved Flutter/Android upgrade.
- WorkManager cannot initialize local backup dependencies in a background isolate.
- Visible-folder Drive access cannot be limited to app-created files with the approved scope.

## Commit Checkpoint

`chore(mobile): prove drive and background dependencies`

## Done When

The dependency set compiles, repository adapters are feasible, the external OAuth checklist is recorded, and Task 02 may proceed without redesigning the Drive boundary.

## Handoff Update

Update `03-implementation-log.md` with versions, proof commands, Android requirements, external blockers, and go/no-go verdict. Update `STATE.md` only if blocked or a locked decision must be reopened.
