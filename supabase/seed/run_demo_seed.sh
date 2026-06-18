#!/usr/bin/env bash
# Seed remote Supabase with demo data for hybrid testing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

: "${DATABASE_URL:?DATABASE_URL required in .env}"

echo "==> Seeding demo data"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seed/demo_data.sql

echo "==> Demo seed complete"
