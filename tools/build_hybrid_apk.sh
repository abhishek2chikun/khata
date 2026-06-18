#!/usr/bin/env bash
# Build hybrid release APK with Supabase dart-defines from .env
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

: "${SUPABASE_URL:?SUPABASE_URL required in .env}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY required in .env}"

if [[ -z "${JAVA_HOME:-}" ]]; then
  if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
  elif [[ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
  fi
fi

echo "==> Building hybrid release APK"
(
  cd mobile
  flutter pub get
  flutter build apk --release \
    --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
    --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" \
    --dart-define=DATA_MODE=hybrid
)

echo "==> APK: mobile/build/app/outputs/flutter-apk/app-release.apk"
