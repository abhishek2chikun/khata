# Internal Billing and Khata System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a robust Flutter + FastAPI + PostgreSQL internal billing system with authenticated cached sessions, ledger-driven khata, atomic invoice creation and cancellation, mobile parity for inventory, sellers, payments, and invoicing, plus practical seed/import paths for real manual testing.

**Architecture:** Use a monorepo with `backend/` for FastAPI and `mobile/` for Flutter. The backend is the only writer of business data and owns auth, idempotency, financial invariants, tax normalization, stock locking, and auditability. Flutter is a thin authenticated client that stores only secure session state and transient invoice-draft state.

**Tech Stack:** FastAPI, SQLAlchemy 2.0, Alembic, PostgreSQL, Pydantic, PyJWT, Argon2/passlib, pytest, Flutter, `dart:io` `HttpClient` (or a future shared HTTP client wrapper), flutter_secure_storage, ChangeNotifier.

## Current Drift Notes

- The current mobile implementation uses `dart:io` networking rather than `dio`, so future tasks should extend the shared client abstractions already in `mobile/lib/services/`.
- Manual QA needs seeded company profile, sellers, products, and invoices because invoicing depends on backend master data and state metadata before the mobile UX can be exercised end-to-end.

---

## Working Rules

- Source spec: `docs/superpowers/specs/2026-04-19-internal-billing-khata-design.md`
- Use TDD throughout.
- All backend tests must run against PostgreSQL, not SQLite.
- All business endpoints require auth.
- All retry-prone writes must be idempotent.
- Use small focused commits after each task.

## Repository Layout

### Root

- `README.md`
- `.gitignore`
- `docs/superpowers/specs/2026-04-19-internal-billing-khata-design.md`
- `docs/superpowers/plans/2026-04-19-internal-billing-khata-implementation.md`

### Backend

- `backend/pyproject.toml`
- `backend/alembic.ini`
- `backend/alembic/env.py`
- `backend/alembic/versions/*.py`
- `backend/app/main.py`
- `backend/app/config.py`
- `backend/app/db.py`
- `backend/app/auth.py`
- `backend/app/core/security.py`
- `backend/app/core/idempotency.py`
- `backend/app/core/pricing.py`
- `backend/app/core/tax.py`
- `backend/app/core/state_codes.py`
- `backend/app/models/base.py`
- `backend/app/models/app_user.py`
- `backend/app/models/user_session.py`
- `backend/app/models/product.py`
- `backend/app/models/seller.py`
- `backend/app/models/company_profile.py`
- `backend/app/models/stock_movement.py`
- `backend/app/models/seller_transaction.py`
- `backend/app/models/invoice.py`
- `backend/app/models/invoice_item.py`
- `backend/app/schemas/common.py`
- `backend/app/schemas/auth.py`
- `backend/app/schemas/product.py`
- `backend/app/schemas/seller.py`
- `backend/app/schemas/company_profile.py`
- `backend/app/schemas/invoice.py`
- `backend/app/services/auth_service.py`
- `backend/app/services/product_service.py`
- `backend/app/services/seller_service.py`
- `backend/app/services/company_profile_service.py`
- `backend/app/services/invoice_service.py`
- `backend/app/routers/auth.py`
- `backend/app/routers/products.py`
- `backend/app/routers/sellers.py`
- `backend/app/routers/company_profile.py`
- `backend/app/routers/invoices.py`
- `backend/app/commands/bootstrap_user.py`
- `backend/app/commands/seed_demo_data.py`
- `backend/tests/conftest.py`
- `backend/tests/commands/test_bootstrap_user.py`
- `backend/tests/commands/test_seed_demo_data.py`
- `backend/tests/services/test_security.py`
- `backend/tests/services/test_idempotency.py`
- `backend/tests/services/test_pricing.py`
- `backend/tests/services/test_tax.py`
- `backend/tests/services/test_invoice_service.py`
- `backend/tests/api/test_auth_api.py`
- `backend/tests/api/test_products_api.py`
- `backend/tests/api/test_sellers_api.py`
- `backend/tests/api/test_company_profile_api.py`
- `backend/tests/api/test_stock_and_ledger_api.py`
- `backend/tests/api/test_invoice_create_api.py`
- `backend/tests/api/test_invoice_cancel_api.py`
- `backend/tests/api/test_end_to_end_flow.py`

### Mobile

- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`
- `mobile/lib/config/api_base_url.dart`
- `mobile/lib/auth/auth_service.dart`
- `mobile/lib/auth/session_store.dart`
- `mobile/lib/auth/auth_controller.dart`
- `mobile/lib/models/api_error.dart`
- `mobile/lib/models/product.dart`
- `mobile/lib/models/seller.dart`
- `mobile/lib/models/seller_ledger.dart`
- `mobile/lib/models/company_profile.dart`
- `mobile/lib/models/invoice_draft.dart`
- `mobile/lib/models/invoice_quote.dart`
- `mobile/lib/models/invoice_detail.dart`
- `mobile/lib/services/api_client.dart`
- `mobile/lib/services/products_service.dart`
- `mobile/lib/services/sellers_service.dart`
- `mobile/lib/services/company_profile_service.dart`
- `mobile/lib/services/invoices_service.dart`
- `mobile/lib/services/payments_service.dart`
- `mobile/lib/state/invoice_draft_controller.dart`
- `mobile/lib/screens/login_screen.dart`
- `mobile/lib/screens/inventory_list_screen.dart`
- `mobile/lib/screens/product_form_screen.dart`
- `mobile/lib/screens/seller_list_screen.dart`
- `mobile/lib/screens/seller_detail_screen.dart`
- `mobile/lib/screens/record_payment_screen.dart`
- `mobile/lib/screens/opening_balance_screen.dart`
- `mobile/lib/screens/balance_adjustment_screen.dart`
- `mobile/lib/screens/create_invoice_screen.dart`
- `mobile/lib/screens/invoice_preview_screen.dart`
- `mobile/lib/widgets/error_banner.dart`
- `mobile/lib/widgets/product_picker.dart`
- `mobile/lib/widgets/seller_picker.dart`
- `mobile/lib/widgets/money_text_field.dart`
- `mobile/test/auth/auth_controller_test.dart`
- `mobile/test/services/api_client_test.dart`
- `mobile/test/state/invoice_draft_controller_test.dart`
- `mobile/test/widgets/login_screen_test.dart`
- `mobile/test/widgets/inventory_list_screen_test.dart`
- `mobile/test/widgets/seller_detail_screen_test.dart`
- `mobile/test/widgets/create_invoice_screen_test.dart`

## Subagent Strategy

- Use one fresh subagent per task.
- Do not start mobile invoice work until backend invoice APIs are passing.
- Always run a code-review subagent after each implemented task.

## Chunk 1: Workspace, Auth, and Shared Backend Foundations

### Task 1: Scaffold repository and basic app entrypoints

**Files:**
- Create: `.gitignore`
- Create: `README.md`
- Create: `backend/pyproject.toml`
- Create: `backend/app/__init__.py`
- Create: `backend/app/main.py`
- Create: `backend/tests/test_app_import.py`
- Create: `mobile/pubspec.yaml`
- Create: `mobile/lib/main.dart`

- [ ] **Step 1: Write the failing smoke test**

```python
from fastapi.testclient import TestClient

from app.main import create_app


def test_health_route_works():
    client = TestClient(create_app())
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

- [ ] **Step 2: Run it and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/test_app_import.py -q`
Expected: FAIL because `app.main` does not exist.

- [ ] **Step 3: Implement minimal scaffolding**

- [ ] **Step 4: Initialize git and rerun test**

Run: `git init && PYTHONPATH=backend pytest backend/tests/test_app_import.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .gitignore README.md backend mobile
git commit -m "chore: scaffold backend and mobile workspaces"
```

### Task 2: Add config and security primitives

**Files:**
- Create: `backend/app/config.py`
- Create: `backend/app/db.py`
- Create: `backend/app/auth.py`
- Create: `backend/app/core/security.py`
- Create: `backend/tests/services/test_security.py`

- [ ] **Step 1: Write failing security tests**

```python
def test_hash_and_verify_password():
    password = "secret123"
    hashed = hash_password(password)
    assert hashed != password
    assert verify_password(password, hashed) is True


def test_access_token_contains_subject():
    token = create_access_token(subject="user-1")
    payload = decode_token(token)
    assert payload["sub"] == "user-1"
```

- [ ] **Step 2: Run them and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/services/test_security.py -q`
Expected: FAIL.

- [ ] **Step 3: Implement settings, DB helpers, and security helpers**

- [ ] **Step 4: Rerun tests**

Run: `PYTHONPATH=backend pytest backend/tests/services/test_security.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/config.py backend/app/db.py backend/app/auth.py backend/app/core/security.py backend/tests/services/test_security.py
git commit -m "feat: add backend config and security helpers"
```

### Task 3: Add auth schema, migrations, fixtures, bootstrap command, and auth APIs

**Files:**
- Create: `backend/app/models/base.py`
- Create: `backend/app/models/app_user.py`
- Create: `backend/app/models/user_session.py`
- Create: `backend/app/schemas/common.py`
- Create: `backend/app/schemas/auth.py`
- Create: `backend/app/services/auth_service.py`
- Create: `backend/app/routers/auth.py`
- Create: `backend/app/commands/bootstrap_user.py`
- Modify: `backend/app/main.py`
- Create: `backend/alembic.ini`
- Create: `backend/alembic/env.py`
- Create: `backend/alembic/versions/0001_auth_tables.py`
- Create: `backend/tests/conftest.py`
- Create: `backend/tests/commands/test_bootstrap_user.py`
- Create: `backend/tests/api/test_auth_api.py`

- [ ] **Step 1: Write failing bootstrap and auth tests**

```python
def test_bootstrap_user_creates_first_user(cli_runner):
    result = cli_runner.invoke(args=["--username", "owner", "--password", "secret123"])
    assert result.exit_code == 0


def test_login_refresh_logout_me_flow(client, seeded_user):
    login = client.post("/auth/login", json={"username": "owner", "password": "secret123"})
    assert login.status_code == 200
    tokens = login.json()

    refresh = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refresh.status_code == 200

    me = client.get("/auth/me", headers={"Authorization": f"Bearer {refresh.json()['access_token']}"})
    assert me.status_code == 200

    logout = client.post("/auth/logout", headers={"Authorization": f"Bearer {refresh.json()['access_token']}"}, json={"refresh_token": refresh.json()["refresh_token"]})
    assert logout.status_code == 200

    refresh_again = client.post("/auth/refresh", json={"refresh_token": refresh.json()["refresh_token"]})
    assert refresh_again.status_code == 401
```

- [ ] **Step 2: Run tests and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/commands/test_bootstrap_user.py backend/tests/api/test_auth_api.py -q`
Expected: FAIL.

- [ ] **Step 3: Implement models, Alembic env, migration, fixtures, bootstrap command, auth routes, and shared error envelope**

Requirements:
- fixtures must use PostgreSQL and Alembic migrations
- `auth_headers` must log in through the real API
- refresh tokens must be rotated and rejected after logout
- all auth errors must use the shared JSON error envelope

- [ ] **Step 4: Run migration smoke commands**

Run: `cd backend && alembic upgrade head`
Expected: PASS.

Run: `cd backend && alembic current`
Expected: current revision is `0001_auth_tables`.

- [ ] **Step 5: Rerun auth tests**

Run: `PYTHONPATH=backend pytest backend/tests/commands/test_bootstrap_user.py backend/tests/api/test_auth_api.py -q`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/app backend/alembic backend/tests/conftest.py backend/tests/commands/test_bootstrap_user.py backend/tests/api/test_auth_api.py README.md
git commit -m "feat: add auth and bootstrap flows"
```

## Chunk 2: Master Data, Stock Foundations, and Common API Behavior

### Task 4: Add product, seller, company profile, and stock-movement foundations

**Files:**
- Create: `backend/app/models/product.py`
- Create: `backend/app/models/seller.py`
- Create: `backend/app/models/company_profile.py`
- Create: `backend/app/models/stock_movement.py`
- Create: `backend/app/schemas/product.py`
- Create: `backend/app/schemas/seller.py`
- Create: `backend/app/schemas/company_profile.py`
- Create: `backend/app/services/product_service.py`
- Create: `backend/app/services/seller_service.py`
- Create: `backend/app/services/company_profile_service.py`
- Create: `backend/app/routers/products.py`
- Create: `backend/app/routers/sellers.py`
- Create: `backend/app/routers/company_profile.py`
- Modify: `backend/app/main.py`
- Create: `backend/alembic/versions/0002_master_data_and_stock_tables.py`
- Create: `backend/tests/api/test_products_api.py`
- Create: `backend/tests/api/test_sellers_api.py`
- Create: `backend/tests/api/test_company_profile_api.py`

- [ ] **Step 1: Write failing product API tests**

```python
def test_create_product_requires_auth_and_creates_opening_stock_movement(client, auth_headers):
    payload = {
        "company": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "item_code": "PEN-001",
        "default_selling_price_excl_tax": "10.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "2.000"
    }
    unauthorized = client.post("/products", json=payload)
    assert unauthorized.status_code == 401

    created = client.post("/products", headers=auth_headers, json=payload)
    assert created.status_code == 201


def test_product_uniqueness_rules_and_filters(client, auth_headers, product):
    duplicate_code = client.post("/products", headers=auth_headers, json={
        "company": "Camlin",
        "category": "Markers",
        "item_name": "Black Marker",
        "item_code": product.item_code,
        "default_selling_price_excl_tax": "15.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": "0.000",
        "low_stock_threshold": "1.000"
    })
    assert duplicate_code.status_code == 409

    filtered = client.get("/products?company=Camlin&category=Pens&search=Blue&active=true&low_stock_only=true", headers=auth_headers)
    assert filtered.status_code == 200


def test_update_product_rejects_blind_stock_rewrite(client, auth_headers, product):
    response = client.put(f"/products/{product.id}", headers=auth_headers, json={"quantity_on_hand": "99.000"})
    assert response.status_code == 400
```

- [ ] **Step 2: Write failing seller and company profile API tests**

```python
def test_seller_crud_and_archive_behavior(client, auth_headers, seller):
    detail = client.get(f"/sellers/{seller.id}", headers=auth_headers)
    assert detail.status_code == 200

    updated = client.put(f"/sellers/{seller.id}", headers=auth_headers, json={
        "name": seller.name,
        "address": "Updated Address",
        "phone": seller.phone,
        "gstin": seller.gstin
    })
    assert updated.status_code == 200


def test_company_profile_create_get_and_error_envelope(client, auth_headers):
    invalid = client.post("/products", headers=auth_headers, json={})
    assert invalid.status_code == 400
    assert invalid.json()["error"]["code"] == "VALIDATION_ERROR"

    created = client.put("/company-profile", headers=auth_headers, json={
        "name": "Acme Traders",
        "address": "Main Road",
        "city": "Pune",
        "state": "Maharashtra",
        "state_code": "27",
        "gstin": "27AAAAA0000A1Z5",
        "phone": "9999999999",
        "email": "owner@example.com",
        "bank_name": "ABC Bank",
        "bank_account": "1234567890",
        "bank_ifsc": "ABC0001234",
        "bank_branch": "Pune",
        "jurisdiction": "Pune"
    })
    assert created.status_code == 200

    fetched = client.get("/company-profile", headers=auth_headers)
    assert fetched.status_code == 200
```

- [ ] **Step 3: Run tests and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/api/test_products_api.py backend/tests/api/test_sellers_api.py backend/tests/api/test_company_profile_api.py -q`
Expected: FAIL.

- [ ] **Step 4: Implement models, migration, services, and routes**

Requirements:
- product uniqueness on `item_code` and `(company, category, item_name)`
- seller uniqueness on `(name, phone)`
- company profile exactly one active row via partial unique index
- product create with non-zero stock creates one `OPENING` stock movement in the same transaction
- product delete and seller delete are archive-only
- `GET /products` supports `company`, `category`, `search`, `active`, and `low_stock_only`
- all errors use `schemas/common.py`

- [ ] **Step 5: Rerun tests**

Run: `PYTHONPATH=backend pytest backend/tests/api/test_products_api.py backend/tests/api/test_sellers_api.py backend/tests/api/test_company_profile_api.py -q`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/app/main.py backend/app/models backend/app/schemas backend/app/services backend/app/routers backend/alembic/versions/0002_master_data_and_stock_tables.py backend/tests/api
git commit -m "feat: add master data and stock foundations"
```

## Chunk 3: Ledger, Payments, Adjustments, Seller Detail, and Shared Idempotency

### Task 5: Add seller transaction model, ledger APIs, payment APIs, adjustment APIs, and stock-adjust APIs

**Files:**
- Create: `backend/app/models/seller_transaction.py`
- Modify: `backend/app/models/stock_movement.py`
- Create: `backend/app/core/idempotency.py`
- Modify: `backend/app/services/product_service.py`
- Modify: `backend/app/services/seller_service.py`
- Modify: `backend/app/routers/products.py`
- Modify: `backend/app/routers/sellers.py`
- Create: `backend/alembic/versions/0003_seller_ledger_tables.py`
- Create: `backend/tests/api/test_stock_and_ledger_api.py`

- [ ] **Step 1: Write failing stock-adjust and ledger tests**

```python
def test_adjust_stock_is_idempotent_and_locks_product_row(client, auth_headers, product):
    payload = {"request_id": str(uuid4()), "quantity_delta": "5.000", "reason": "Stock count correction"}
    first = client.post(f"/products/{product.id}/adjust-stock", headers=auth_headers, json=payload)
    second = client.post(f"/products/{product.id}/adjust-stock", headers=auth_headers, json=payload)
    assert first.status_code == 200
    assert second.json()["quantity_on_hand"] == first.json()["quantity_on_hand"]

    conflict = client.post(f"/products/{product.id}/adjust-stock", headers=auth_headers, json={"request_id": payload["request_id"], "quantity_delta": "7.000", "reason": "Different correction"})
    assert conflict.status_code == 409


def test_opening_balance_payment_adjustment_and_ledger_view(client, auth_headers, seller):
    opening = client.post(f"/sellers/{seller.id}/opening-balance", headers=auth_headers, json={"request_id": str(uuid4()), "amount": "500.00", "occurred_on": "2026-04-19"})
    assert opening.status_code == 201

    payment_request_id = str(uuid4())
    payment = client.post("/payments", headers=auth_headers, json={"request_id": payment_request_id, "seller_id": str(seller.id), "amount": "100.00", "occurred_on": "2026-04-20", "notes": "Cash"})
    assert payment.status_code == 201

    adjustment = client.post(f"/sellers/{seller.id}/balance-adjustment", headers=auth_headers, json={"request_id": str(uuid4()), "direction": "INCREASE", "amount": "50.00", "occurred_on": "2026-04-21", "notes": "Legacy correction"})
    assert adjustment.status_code == 201

    payment_conflict = client.post("/payments", headers=auth_headers, json={"request_id": payment_request_id, "seller_id": str(seller.id), "amount": "150.00", "occurred_on": "2026-04-20", "notes": "Changed"})
    assert payment_conflict.status_code == 409

    ledger = client.get(f"/sellers/{seller.id}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
```

- [ ] **Step 2: Run tests and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/api/test_stock_and_ledger_api.py -q`
Expected: FAIL.

- [ ] **Step 3: Implement seller transactions and ledger routes**

Requirements:
- one `OPENING_BALANCE` per seller via partial unique index
- manual rows idempotent by `request_id` and `request_hash`
- same manual `request_id` with different payload must return `409 IDEMPOTENCY_CONFLICT`
- `GET /sellers` returns derived `pending_balance`
- `GET /sellers/{seller_id}/ledger` returns seller profile, derived balance, transactions, and invoice history in this task
- `POST /payments` must be implemented and idempotent
- `POST /sellers/{seller_id}/balance-adjustment` must be implemented and idempotent
- manual stock adjustments lock product rows with `SELECT ... FOR UPDATE`
- reject new operational writes on archived sellers/products
- enforce DB `CHECK` constraints for manual-vs-invoice row shapes and invoice-link requirements

- [ ] **Step 4: Rerun tests**

Run: `PYTHONPATH=backend pytest backend/tests/api/test_stock_and_ledger_api.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/models/seller_transaction.py backend/app/models/stock_movement.py backend/app/services backend/app/routers backend/alembic/versions/0003_seller_ledger_tables.py backend/tests/api/test_stock_and_ledger_api.py
git commit -m "feat: add seller ledger and stock adjustment APIs"
```

## Chunk 4: Invoice Core and Financial Transactions

### Task 6: Add pricing, tax, invoice tables, and invoice numbering foundations

**Files:**
 - Create: `backend/app/core/pricing.py`
 - Create: `backend/app/core/tax.py`
 - Create: `backend/app/core/state_codes.py`
 - Create: `backend/app/models/invoice.py`
 - Create: `backend/app/models/invoice_item.py`
 - Create: `backend/alembic/versions/0004_invoice_tables.py`
 - Create: `backend/tests/services/test_idempotency.py`
 - Create: `backend/tests/services/test_pricing.py`
 - Create: `backend/tests/services/test_tax.py`

- [ ] **Step 1: Write failing unit tests for hashing, pricing, and tax resolution**

```python
def test_same_invoice_payload_hashes_identically_across_retries():
    payload = {"items": [{"product_id": "p1", "quantity": "2.000", "discount_percent": "0.00"}]}
    assert canonical_request_hash(payload) == canonical_request_hash(payload)


def test_tax_inclusive_price_normalizes_correctly():
    line = normalize_line(quantity=Decimal("2"), unit_price=Decimal("118.00"), pricing_mode="TAX_INCLUSIVE", gst_rate=Decimal("18.00"), discount_percent=Decimal("5.00"))
    assert line.unit_price_excl_tax == Decimal("100.00")
```

- [ ] **Step 2: Run tests and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/services/test_idempotency.py backend/tests/services/test_pricing.py backend/tests/services/test_tax.py -q`
Expected: FAIL.

- [ ] **Step 3: Implement core modules and invoice tables**

Requirements:
- invoice item order is part of canonical request hashing
- `place_of_supply_state` derived from canonical state-code map
- invoice tables store seller/company snapshots, tax regime, split tax amounts, and cancel audit fields
- add sequence-backed `invoice_number` generation in schema and model layer

- [ ] **Step 4: Rerun tests**

Run: `PYTHONPATH=backend pytest backend/tests/services/test_idempotency.py backend/tests/services/test_pricing.py backend/tests/services/test_tax.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
 git add backend/app/core backend/app/models/invoice.py backend/app/models/invoice_item.py backend/alembic/versions/0004_invoice_tables.py backend/tests/services
 git commit -m "feat: add invoice schema and financial core"
```

### Task 7: Build quote and atomic invoice create flow

**Files:**
- Create: `backend/app/schemas/invoice.py`
- Create: `backend/app/services/invoice_service.py`
- Create: `backend/app/routers/invoices.py`
- Create: `backend/tests/services/test_invoice_service.py`
- Create: `backend/tests/api/test_invoice_create_api.py`

- [ ] **Step 1: Write failing quote/create tests**

```python
def test_quote_requires_company_profile_state_and_returns_totals(client, auth_headers, seeded_company_profile, seller, product):
    payload = {
        "seller_id": str(seller.id),
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "place_of_supply_state_code": "27",
        "items": [{"product_id": str(product.id), "quantity": "2.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"}]
    }
    response = client.post("/invoices/quote", headers=auth_headers, json=payload)
    assert response.status_code == 200


def test_quote_rejects_missing_or_unresolved_tax_state_inputs(client, auth_headers, seller, product):
    payload = {
        "seller_id": str(seller.id),
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "items": [{"product_id": str(product.id), "quantity": "2.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"}]
    }
    response = client.post("/invoices/quote", headers=auth_headers, json=payload)
    assert response.status_code == 400


def test_create_credit_invoice_is_atomic_and_idempotent(client, auth_headers, seeded_company_profile, seller, product):
    payload = {
        "request_id": str(uuid4()),
        "seller_id": str(seller.id),
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "place_of_supply_state_code": "27",
        "items": [{"product_id": str(product.id), "quantity": "2.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"}]
    }
    first = client.post("/invoices", headers=auth_headers, json=payload)
    second = client.post("/invoices", headers=auth_headers, json=payload)
    assert first.status_code == 201
    assert second.json()["invoice"]["id"] == first.json()["invoice"]["id"]


def test_paid_invoice_creates_no_credit_ledger_row(client, auth_headers, seeded_company_profile, seller, product):
    payload = {
        "request_id": str(uuid4()),
        "seller_id": str(seller.id),
        "invoice_date": "2026-04-19",
        "payment_mode": "PAID",
        "place_of_supply_state_code": "27",
        "items": [{"product_id": str(product.id), "quantity": "1.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"}]
    }
    response = client.post("/invoices", headers=auth_headers, json=payload)
    assert response.status_code == 201


def test_invoice_create_rolls_back_on_internal_failure(client, auth_headers, seeded_company_profile, seller, product, monkeypatch):
    payload = {
        "request_id": str(uuid4()),
        "seller_id": str(seller.id),
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "place_of_supply_state_code": "27",
        "items": [{"product_id": str(product.id), "quantity": "2.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"}]
    }
    assert payload["request_id"]


def test_negative_stock_warning_is_returned_on_create(client, auth_headers, seeded_company_profile, seller, product):
    payload = {
        "request_id": str(uuid4()),
        "seller_id": str(seller.id),
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "place_of_supply_state_code": "27",
        "items": [{"product_id": str(product.id), "quantity": "999.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"}]
    }
    response = client.post("/invoices", headers=auth_headers, json=payload)
    assert response.status_code == 201
    assert response.json()["warnings"]
```

- [ ] **Step 2: Run tests and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/services/test_invoice_service.py backend/tests/api/test_invoice_create_api.py -q`
Expected: FAIL.

- [ ] **Step 3: Implement quote and create**

Requirements:
- quote returns normalized totals and quote-time warnings
- quote rejects missing unresolved `place_of_supply_state_code`
- quote rejects incomplete company state metadata
- quote validates seller state name/code consistency before deriving tax regime
- create locks products in deterministic order
- create inserts invoice, invoice items, stock movements, and credit ledger row in one transaction
- create returns commit-time warnings array
- totals in header must equal sums of item totals
- paid invoices must not create seller credit ledger entries
- partial failure must roll back invoice header, items, stock updates, and ledger writes
- insufficient stock path must still succeed and return warnings
- add service or integration coverage for overlapping product locks to catch deadlock-prone ordering regressions
- add DB constraint coverage for invoice cancel field consistency and invoice-number sequence behavior

- [ ] **Step 4: Rerun tests**

Run: `PYTHONPATH=backend pytest backend/tests/services/test_invoice_service.py backend/tests/api/test_invoice_create_api.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/schemas/invoice.py backend/app/services/invoice_service.py backend/app/routers/invoices.py backend/tests/services/test_invoice_service.py backend/tests/api/test_invoice_create_api.py
git commit -m "feat: add quote and atomic invoice create"
```

### Task 8: Build invoice cancel, list, and detail flows

**Files:**
- Modify: `backend/app/services/invoice_service.py`
- Modify: `backend/app/routers/invoices.py`
- Create: `backend/tests/api/test_invoice_cancel_api.py`

- [ ] **Step 1: Write failing cancel/list/detail tests**

```python
def test_cancel_invoice_is_idempotent_and_reverses_stock_and_credit(client, auth_headers, created_credit_invoice):
    payload = {"request_id": str(uuid4()), "cancel_reason": "Wrong quantity"}
    first = client.post(f"/invoices/{created_credit_invoice.id}/cancel", headers=auth_headers, json=payload)
    second = client.post(f"/invoices/{created_credit_invoice.id}/cancel", headers=auth_headers, json=payload)
    assert first.status_code == 200
    assert second.json()["invoice"]["status"] == "CANCELED"


def test_cancel_with_new_request_after_completion_returns_already_canceled(client, auth_headers, created_credit_invoice):
    response = client.post(f"/invoices/{created_credit_invoice.id}/cancel", headers=auth_headers, json={"request_id": str(uuid4()), "cancel_reason": "Another try"})
    assert response.status_code == 409


def test_invoice_list_filters_work(client, auth_headers):
    response = client.get("/invoices?from_date=2026-04-01&to_date=2026-04-30&status=ACTIVE&payment_mode=CREDIT&invoice_number=1001", headers=auth_headers)
    assert response.status_code == 200


def test_invoice_detail_returns_persisted_snapshots(client, auth_headers, created_credit_invoice):
    response = client.get(f"/invoices/{created_credit_invoice.id}", headers=auth_headers)
    assert response.status_code == 200
```

- [ ] **Step 2: Run tests and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests/api/test_invoice_cancel_api.py -q`
Expected: FAIL.

- [ ] **Step 3: Implement cancel and historical reads**

Requirements:
- repeated same cancel payload returns success-equivalent response
- same cancel `request_id` with different payload returns `409 IDEMPOTENCY_CONFLICT`
- different cancel `request_id` after completed cancellation returns `409 INVOICE_ALREADY_CANCELED`
- list/detail use persisted snapshots and preserve line order and tax split data
- list filters must support date range, seller, status, payment mode, and invoice number

- [ ] **Step 4: Rerun tests**

Run: `PYTHONPATH=backend pytest backend/tests/api/test_invoice_cancel_api.py backend/tests/api/test_invoice_create_api.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/invoice_service.py backend/app/routers/invoices.py backend/tests/api/test_invoice_cancel_api.py backend/tests/api/test_invoice_create_api.py
git commit -m "feat: add invoice cancel and history APIs"
```

## Chunk 5: Flutter App

### Task 9: Build cached mobile login flow

**Files:**
- Create: `mobile/lib/auth/auth_service.dart`
- Create: `mobile/lib/auth/session_store.dart`
- Create: `mobile/lib/auth/auth_controller.dart`
- Create: `mobile/lib/screens/login_screen.dart`
- Modify: `mobile/lib/main.dart`
- Create: `mobile/test/auth/auth_controller_test.dart`
- Create: `mobile/test/widgets/login_screen_test.dart`

- [ ] **Step 1: Write failing auth-controller tests**

```dart
test('restores cached session without forcing login', () async {
  final controller = AuthController(fakeAuthService, fakeSessionStoreWithTokens);
  await controller.restoreSession();
  expect(controller.isAuthenticated, isTrue);
});
```

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test mobile/test/auth/auth_controller_test.dart mobile/test/widgets/login_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement auth UI and secure session storage**

- [ ] **Step 4: Rerun tests**

Run: `flutter test mobile/test/auth/auth_controller_test.dart mobile/test/widgets/login_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/auth mobile/lib/screens/login_screen.dart mobile/lib/main.dart mobile/test/auth mobile/test/widgets/login_screen_test.dart
git commit -m "feat: add mobile cached login flow"
```

### Task 10: Build mobile API client and inventory screens

**Files:**
- Create: `mobile/lib/models/api_error.dart`
- Create: `mobile/lib/models/product.dart`
- Create: `mobile/lib/services/api_client.dart`
- Create: `mobile/lib/services/products_service.dart`
- Create: `mobile/lib/screens/inventory_list_screen.dart`
- Create: `mobile/lib/screens/product_form_screen.dart`
- Create: `mobile/lib/widgets/error_banner.dart`
- Create: `mobile/test/services/api_client_test.dart`
- Create: `mobile/test/widgets/inventory_list_screen_test.dart`

- [ ] **Step 1: Write failing API client and screen tests**

```dart
test('api client refreshes token once after 401', () async {
  final response = await apiClient.get('/products');
  expect(response.statusCode, 200);
});
```

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test mobile/test/services/api_client_test.dart mobile/test/widgets/inventory_list_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement client, product DTOs, and inventory screens**

Requirements:
- refresh once on 401, then fail cleanly
- archived products visually blocked from new actions where relevant

- [ ] **Step 4: Rerun tests**

Run: `flutter test mobile/test/services/api_client_test.dart mobile/test/widgets/inventory_list_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
 git add mobile/lib/models/api_error.dart mobile/lib/models/product.dart mobile/lib/services/api_client.dart mobile/lib/services/products_service.dart mobile/lib/screens/inventory_list_screen.dart mobile/lib/screens/product_form_screen.dart mobile/lib/widgets/error_banner.dart mobile/test/services/api_client_test.dart mobile/test/widgets/inventory_list_screen_test.dart
 git commit -m "feat: add mobile inventory flows"
```

### Task 11: Build mobile seller detail, payment, and adjustment flows

**Files:**
- Create: `mobile/lib/models/seller.dart`
- Create: `mobile/lib/models/seller_ledger.dart`
- Create: `mobile/lib/models/company_profile.dart`
- Create: `mobile/lib/services/sellers_service.dart`
- Create: `mobile/lib/screens/record_payment_screen.dart`
- Create: `mobile/lib/screens/opening_balance_screen.dart`
- Create: `mobile/lib/screens/balance_adjustment_screen.dart`
- Create: `mobile/lib/services/payments_service.dart`
- Create: `mobile/lib/services/company_profile_service.dart`
- Create: `mobile/lib/screens/seller_list_screen.dart`
- Modify: `mobile/lib/screens/seller_detail_screen.dart`
- Create: `mobile/lib/screens/seller_detail_screen.dart`
- Create: `mobile/test/widgets/record_payment_screen_test.dart`
- Create: `mobile/test/widgets/seller_detail_screen_test.dart`

- [ ] **Step 1: Write failing payment and adjustment screen tests**

```dart
test('record payment submits request id and refreshes seller detail', () async {
  expect(true, isFalse);
});
```

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test mobile/test/widgets/record_payment_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement payment, opening balance, and balance-adjustment screens**

Requirements:
- each submission generates and sends a `request_id`
- screens refresh seller detail after success
- API errors use the shared error banner pattern

- [ ] **Step 4: Rerun tests**

Run: `flutter test mobile/test/widgets/record_payment_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/screens/record_payment_screen.dart mobile/lib/screens/opening_balance_screen.dart mobile/lib/screens/balance_adjustment_screen.dart mobile/lib/services/payments_service.dart mobile/lib/screens/seller_detail_screen.dart mobile/test/widgets/record_payment_screen_test.dart
git commit -m "feat: add mobile payment and adjustment flows"
```

### Task 12: Build mobile invoice draft, preview, and submit flow

**Files:**
- Create: `mobile/lib/models/invoice_draft.dart`
- Create: `mobile/lib/models/invoice_quote.dart`
- Create: `mobile/lib/models/invoice_detail.dart`
- Create: `mobile/lib/services/invoices_service.dart`
- Create: `mobile/lib/state/invoice_draft_controller.dart`
- Create: `mobile/lib/screens/create_invoice_screen.dart`
- Create: `mobile/lib/screens/invoice_preview_screen.dart`
- Create: `mobile/lib/widgets/product_picker.dart`
- Create: `mobile/lib/widgets/seller_picker.dart`
- Create: `mobile/lib/widgets/money_text_field.dart`
- Create: `mobile/test/state/invoice_draft_controller_test.dart`
- Create: `mobile/test/widgets/create_invoice_screen_test.dart`

- [ ] **Step 1: Write failing invoice draft tests**

```dart
test('invoice draft reuses request id across safe retry', () async {
  final controller = InvoiceDraftController(fakeInvoicesService);
  controller.prepareForSubmit();
  final first = controller.requestId;
  await controller.retrySubmitAfterTimeout();
  expect(controller.requestId, first);
});
```

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test mobile/test/state/invoice_draft_controller_test.dart mobile/test/widgets/create_invoice_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement invoice draft and preview flow**

Requirements:
- quote before submit
- keep draft intact on error
- show commit-time warnings from create response
- clear `request_id` only after success or intentional edit

- [ ] **Step 4: Rerun tests**

Run: `flutter test mobile/test/state/invoice_draft_controller_test.dart mobile/test/widgets/create_invoice_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/models/invoice_* mobile/lib/services/invoices_service.dart mobile/lib/services/payments_service.dart mobile/lib/state/invoice_draft_controller.dart mobile/lib/screens/create_invoice_screen.dart mobile/lib/screens/invoice_preview_screen.dart mobile/lib/widgets mobile/test/state mobile/test/widgets/create_invoice_screen_test.dart
git commit -m "feat: add mobile invoice flow"
```

## Chunk 6: Final Verification

### Task 13: End-to-end verification and docs

**Files:**
- Modify: `README.md`
- Create: `backend/tests/api/test_end_to_end_flow.py`

- [ ] **Step 1: Write failing end-to-end test**

```python
def test_full_credit_sale_and_payment_flow(client, auth_headers, seeded_company_profile):
    assert True is False
```

- [ ] **Step 2: Run full backend suite and verify failure**

Run: `PYTHONPATH=backend pytest backend/tests -q`
Expected: FAIL because end-to-end test is incomplete.

- [ ] **Step 3: Implement end-to-end test and finalize docs**

Docs must cover:
- PostgreSQL setup
- Alembic migrate commands
- first-user bootstrap
- backend run command
- Flutter run command
- full test commands

- [ ] **Step 4: Run final verification**

Run: `PYTHONPATH=backend pytest backend/tests -q`
Expected: PASS.

Run: `flutter test mobile/test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md backend/tests/api/test_end_to_end_flow.py
git commit -m "chore: verify end-to-end billing workflow"
```

## Execution Order

1. Chunk 1
2. Chunk 2
3. Chunk 3
4. Chunk 4
5. Chunk 5
6. Chunk 6

## Verification Checklist

- All business endpoints require auth.
- Refresh tokens rotate and are revoked correctly.
- Product creation with initial stock creates exactly one `OPENING` stock movement.
- Seller balance is ledger-derived only.
- Payments and balance adjustments are idempotent.
- Invoice create and cancel are atomic and idempotent.
- Mobile session restore avoids repeated login prompts.
- Mobile invoice retry reuses the same `request_id`.

Plan complete and saved to `docs/superpowers/plans/2026-04-19-internal-billing-khata-implementation.md`. Ready to execute?
