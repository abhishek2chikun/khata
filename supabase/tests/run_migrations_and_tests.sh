#!/usr/bin/env bash
# Apply hybrid Supabase migrations and run SQL smoke tests against remote Postgres.
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

echo "==> Applying migrations via psql"
for f in supabase/migrations/*.sql; do
  echo "    $f"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f" >/dev/null
done

echo "==> Running SQL tests"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/sql_smoke_tests.sql

echo "==> All SQL tests passed"
