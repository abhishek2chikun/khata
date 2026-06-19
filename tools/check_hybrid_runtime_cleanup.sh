#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for removed_path in \
  mobile/lib/backup \
  mobile/lib/config/api_base_url.dart \
  mobile/lib/local/local_auth_service.dart \
  mobile/lib/screens/local_first_user_setup_screen.dart \
  mobile/lib/services/api_client.dart; do
  if [[ -e "$removed_path" ]]; then
    echo "legacy runtime path still exists: $removed_path" >&2
    exit 1
  fi
done

forbidden='DataMode\.(api|local)|class Api[A-Za-z]+Service|class HttpAuthService|package:workmanager|package:google_sign_in|package:googleapis|BackupScreen|LocalFirstUserSetupScreen|initializeLocalBackupPlatformServices'
if rg -n "$forbidden" mobile/lib mobile/test mobile/pubspec.yaml; then
  echo "legacy runtime symbol remains" >&2
  exit 1
fi

if rg -n 'google_sign_in|googleapis|workmanager|file_picker|cryptography' mobile/pubspec.lock; then
  echo "legacy package remains in dependency lock" >&2
  exit 1
fi

echo "hybrid runtime cleanup check passed"
