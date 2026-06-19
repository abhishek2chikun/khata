#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

required=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  SUPABASE_SERVICE_ROLE_KEY
  SUPABASE_TEST_USER_FATHER_EMAIL
  SUPABASE_TEST_USER_FATHER_PASSWORD
  SUPABASE_TEST_USER_BROTHER_EMAIL
  SUPABASE_TEST_USER_BROTHER_PASSWORD
)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "missing required environment variable: $name" >&2
    exit 1
  fi
done

cd mobile
flutter test live_test/remote_two_client_sync_test.dart \
  --concurrency=1 \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
  --dart-define=PRIMARY_EMAIL="$SUPABASE_TEST_USER_FATHER_EMAIL" \
  --dart-define=PRIMARY_PASSWORD="$SUPABASE_TEST_USER_FATHER_PASSWORD" \
  --dart-define=SECONDARY_EMAIL="$SUPABASE_TEST_USER_BROTHER_EMAIL" \
  --dart-define=SECONDARY_PASSWORD="$SUPABASE_TEST_USER_BROTHER_PASSWORD"
