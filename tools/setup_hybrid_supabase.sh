#!/usr/bin/env bash
# One-shot remote setup: auth users + master catalog seed in Supabase.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 tools/provision_supabase_auth_users.py
python3 tools/seed_supabase_master_catalog.py

echo "==> Hybrid remote setup complete"
