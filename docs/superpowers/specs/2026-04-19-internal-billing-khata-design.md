# Production-Grade Internal Billing and Khata System Design

## Summary

- Build one Flutter mobile app and one FastAPI backend backed by PostgreSQL.
- All writes go through the API. The mobile app is never the source of truth for business data.
- The financially critical flows are inventory management, seller and khata management, invoice creation, payment recording, and company profile settings.
- The app requires login, but the session should stay cached securely so users do not need to log in on every app open.
- Invoices are immutable after creation. Corrections happen through cancel-and-recreate only.
- Seller pending balance is derived from ledger transactions, never stored directly on the seller row.

## Confirmed Product Decisions

- Authentication for v1: simple login is required.
- Login must be cached securely on the device so users usually stay signed in between app launches.
- Offline invoice save behavior: blocked until backend is reachable.
- Payment allocation: seller-level only, not allocated against specific invoices.
- Invoice price entry: support both `PRE_TAX` and `TAX_INCLUSIVE` entry modes.
- Invoice cancellation: reverse both stock and khata effects.
- Previous seller balance must be supported even without invoices.

## Goals

- Replace manual billing and khata for a small stationery distribution business.
- Prioritize correctness, simplicity, and maintainability over scalability.
- Preserve the current product's strongest workflows while removing schema drift and inconsistent accounting logic.

## Non-Goals For V1

- No websockets.
- No real-time sync.
- No microservices.
- No local-first write model.
- No advanced analytics, OCR import, or spreadsheet bulk import in the first release.
- No invoice editing after creation.

## High-Level Architecture

### System Shape

- Flutter is a thin client with screens, models, and service classes.
- FastAPI owns all write rules and business workflows.
- PostgreSQL is the system of record.
- All critical accounting and stock updates occur inside database transactions.

### Core Modules

- Inventory
  - Product CRUD
  - Stock visibility
  - Low-stock warnings
- Sellers and khata
  - Seller CRUD
  - Opening balance entry
  - Payment entry
  - Ledger view
  - Seller invoice history
- Authentication
  - Login
  - Token refresh
  - Logout
- Invoicing
  - Quote calculation
  - Atomic invoice creation
  - Invoice list and detail
  - Invoice cancellation
- Settings
  - Company profile for invoice branding and bank details

### Write Ownership

- Flutter may compute temporary display values, but the backend is authoritative.
- The API performs validation, normalization, transaction handling, and persistence.
- PostgreSQL constraints backstop application-level validation.

## Recommended Architecture Approach

### Selected Approach

- Single FastAPI app + PostgreSQL + simple Flutter app.

### Why This Approach

- It matches the hard requirement that all writes must go through the API.
- It keeps invoice and khata logic centralized in one backend.
- It avoids offline synchronization complexity and duplicate accounting paths.
- It is maintainable for a small internal team and future enhancements.

### Rejected Alternatives

- A heavier layered backend was rejected because it adds ceremony without enough benefit for this size of system.
- A local cache plus sync queue in Flutter was rejected because it conflicts with the API-only write rule and increases financial correctness risk.

## Database Schema

Use PostgreSQL with `UUID` primary keys for entities and a stable sequence-backed `invoice_number` for human-visible numbering.

### 1. `products`

- `id UUID PRIMARY KEY`
- `company TEXT NOT NULL`
- `category TEXT NOT NULL`
- `item_name TEXT NOT NULL`
- `item_code TEXT NOT NULL UNIQUE`
- `buying_price_excl_tax NUMERIC(14,2) NULL`
- `buying_gst_rate NUMERIC(5,2) NULL`
- `default_selling_price_excl_tax NUMERIC(14,2) NOT NULL`
- `default_gst_rate NUMERIC(5,2) NOT NULL`
- `quantity_on_hand NUMERIC(14,3) NOT NULL DEFAULT 0`
- `low_stock_threshold NUMERIC(14,3) NOT NULL DEFAULT 0`
- `is_active BOOLEAN NOT NULL DEFAULT TRUE`
- `created_at TIMESTAMPTZ NOT NULL`
- `updated_at TIMESTAMPTZ NOT NULL`
- Unique constraint on `(company, category, item_name)` to preserve current business behavior.

### 2. `sellers`

- `id UUID PRIMARY KEY`
- `name TEXT NOT NULL`
- `address TEXT NOT NULL DEFAULT ''`
- `state TEXT NULL`
- `state_code TEXT NULL`
- `phone TEXT NULL`
- `gstin TEXT NULL`
- `is_active BOOLEAN NOT NULL DEFAULT TRUE`
- `created_at TIMESTAMPTZ NOT NULL`
- `updated_at TIMESTAMPTZ NOT NULL`
- Unique constraint on `(name, phone)`.

### 3. `company_profiles`

- `id UUID PRIMARY KEY`
- `name TEXT NOT NULL`
- `address TEXT NOT NULL`
- `city TEXT NOT NULL`
- `state TEXT NOT NULL`
- `state_code TEXT NOT NULL`
- `gstin TEXT NULL`
- `phone TEXT NULL`
- `email TEXT NULL`
- `bank_name TEXT NULL`
- `bank_account TEXT NULL`
- `bank_ifsc TEXT NULL`
- `bank_branch TEXT NULL`
- `jurisdiction TEXT NULL`
- `is_active BOOLEAN NOT NULL DEFAULT TRUE`
- `created_at TIMESTAMPTZ NOT NULL`
- `updated_at TIMESTAMPTZ NOT NULL`

Rules:

- exactly one row is active at a time
- `GET /company-profile` always returns the single active row
- `PUT /company-profile` updates that active row, or creates it if none exists yet during first-time setup
- enforce the invariant with a database-level partial unique index such as one active row where `is_active = TRUE`
- setup and update flows must run transactionally so concurrent requests cannot leave two active rows

### Authentication Tables

#### `app_users`

- `id UUID PRIMARY KEY`
- `username TEXT NOT NULL UNIQUE`
- `password_hash TEXT NOT NULL`
- `display_name TEXT NULL`
- `is_active BOOLEAN NOT NULL DEFAULT TRUE`
- `created_at TIMESTAMPTZ NOT NULL`
- `updated_at TIMESTAMPTZ NOT NULL`

Rules:

- v1 does not require roles
- the system can run with one shared business account or a small set of staff accounts
- passwords must be stored only as secure hashes, never plaintext
- the first active app user must be created through an operational bootstrap command or seed script before the system is opened for use

#### `user_sessions`

- `id UUID PRIMARY KEY`
- `user_id UUID NOT NULL REFERENCES app_users(id)`
- `refresh_token_hash TEXT NOT NULL`
- `expires_at TIMESTAMPTZ NOT NULL`
- `revoked_at TIMESTAMPTZ NULL`
- `last_used_at TIMESTAMPTZ NOT NULL`
- `created_at TIMESTAMPTZ NOT NULL`

Rules:

- access tokens are short-lived bearer tokens
- refresh tokens are long-lived and stored hashed in the database
- Flutter stores tokens in secure device storage and silently refreshes sessions when possible
- deployment bootstrap must create the first active app user before business use begins

### 4. `invoices`

- `id UUID PRIMARY KEY`
- `request_id UUID NOT NULL UNIQUE`
- `request_hash TEXT NOT NULL`
- `invoice_number BIGINT NOT NULL UNIQUE`
- `seller_id UUID NOT NULL REFERENCES sellers(id)`
- seller snapshot fields:
  - `seller_name TEXT NOT NULL`
- `seller_address TEXT NOT NULL`
- `seller_state TEXT NULL`
- `seller_state_code TEXT NULL`
- `seller_phone TEXT NULL`
- `seller_gstin TEXT NULL`
- `place_of_supply_state TEXT NOT NULL`
- `place_of_supply_state_code TEXT NOT NULL`
- company snapshot fields:
  - `company_name TEXT NOT NULL`
  - `company_address TEXT NOT NULL`
  - `company_city TEXT NOT NULL`
  - `company_state TEXT NOT NULL`
  - `company_state_code TEXT NOT NULL`
  - `company_gstin TEXT NULL`
  - `company_phone TEXT NULL`
  - `company_email TEXT NULL`
  - `company_bank_name TEXT NULL`
  - `company_bank_account TEXT NULL`
  - `company_bank_ifsc TEXT NULL`
  - `company_bank_branch TEXT NULL`
  - `company_jurisdiction TEXT NULL`
- `invoice_date DATE NOT NULL`
- `tax_regime TEXT NOT NULL CHECK (tax_regime IN ('INTRA_STATE', 'INTER_STATE'))`
- `status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'CANCELED'))`
- `payment_mode TEXT NOT NULL CHECK (payment_mode IN ('PAID', 'CREDIT'))`
- `subtotal NUMERIC(14,2) NOT NULL`
- `discount_total NUMERIC(14,2) NOT NULL`
- `taxable_total NUMERIC(14,2) NOT NULL`
- `gst_total NUMERIC(14,2) NOT NULL`
- `grand_total NUMERIC(14,2) NOT NULL`
- `notes TEXT NULL`
- `created_by_user_id UUID NOT NULL REFERENCES app_users(id)`
- `cancel_request_id UUID NULL UNIQUE`
- `cancel_request_hash TEXT NULL`
- `canceled_by_user_id UUID NULL REFERENCES app_users(id)`
- `cancel_reason TEXT NULL`
- `canceled_at TIMESTAMPTZ NULL`
- `created_at TIMESTAMPTZ NOT NULL`

Rules:

- if `status = 'ACTIVE'`, then `cancel_request_id`, `cancel_request_hash`, `canceled_by_user_id`, `cancel_reason`, and `canceled_at` must all be null
- if `status = 'CANCELED'`, then `cancel_request_id`, `cancel_request_hash`, `canceled_by_user_id`, `cancel_reason`, and `canceled_at` must all be non-null
- enforce cancel-field consistency with database `CHECK` constraints

### 5. `invoice_items`

- `id UUID PRIMARY KEY`
- `invoice_id UUID NOT NULL REFERENCES invoices(id)`
- `product_id UUID NOT NULL REFERENCES products(id)`
- `line_number INTEGER NOT NULL`
- Snapshot fields:
  - `product_name TEXT NOT NULL`
  - `product_code TEXT NOT NULL`
  - `company TEXT NOT NULL`
  - `category TEXT NOT NULL`
- `quantity NUMERIC(14,3) NOT NULL`
- `pricing_mode TEXT NOT NULL CHECK (pricing_mode IN ('PRE_TAX', 'TAX_INCLUSIVE'))`
- `entered_unit_price NUMERIC(14,2) NOT NULL`
- `unit_price_excl_tax NUMERIC(14,2) NOT NULL`
- `unit_price_incl_tax NUMERIC(14,2) NOT NULL`
- `gst_rate NUMERIC(5,2) NOT NULL`
- `cgst_rate NUMERIC(5,2) NOT NULL DEFAULT 0`
- `sgst_rate NUMERIC(5,2) NOT NULL DEFAULT 0`
- `igst_rate NUMERIC(5,2) NOT NULL DEFAULT 0`
- `discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0`
- `discount_amount NUMERIC(14,2) NOT NULL`
- `taxable_amount NUMERIC(14,2) NOT NULL`
- `gst_amount NUMERIC(14,2) NOT NULL`
- `cgst_amount NUMERIC(14,2) NOT NULL DEFAULT 0`
- `sgst_amount NUMERIC(14,2) NOT NULL DEFAULT 0`
- `igst_amount NUMERIC(14,2) NOT NULL DEFAULT 0`
- `line_total NUMERIC(14,2) NOT NULL`

Rules:

- `line_number` preserves the original invoice line order for detail views and PDF rendering
- line ordering is part of the persisted invoice snapshot
- unique constraint on `(invoice_id, line_number)`
- `cgst_amount + sgst_amount + igst_amount` must equal `gst_amount`
- `cgst_rate + sgst_rate + igst_rate` must equal `gst_rate`

### 6. `seller_transactions`

- `id UUID PRIMARY KEY`
- `seller_id UUID NOT NULL REFERENCES sellers(id)`
- `invoice_id UUID NULL REFERENCES invoices(id)`
- `request_id UUID NULL UNIQUE`
- `request_hash TEXT NULL`
- `entry_type TEXT NOT NULL CHECK (entry_type IN ('OPENING_BALANCE', 'CREDIT_SALE', 'PAYMENT', 'INVOICE_CANCEL_REVERSAL', 'BALANCE_INCREASE_ADJUSTMENT', 'BALANCE_DECREASE_ADJUSTMENT'))`
- `amount NUMERIC(14,2) NOT NULL CHECK (amount > 0)`
- `occurred_on DATE NOT NULL`
- `notes TEXT NULL`
- `created_by_user_id UUID NOT NULL REFERENCES app_users(id)`
- `created_at TIMESTAMPTZ NOT NULL`

Balance formula:

- `OPENING_BALANCE` adds to pending balance
- `CREDIT_SALE` adds to pending balance
- `PAYMENT` subtracts from pending balance
- `INVOICE_CANCEL_REVERSAL` subtracts from pending balance
- `BALANCE_INCREASE_ADJUSTMENT` adds to pending balance
- `BALANCE_DECREASE_ADJUSTMENT` subtracts from pending balance

This allows previous pending dues to exist even when the seller has no invoice history in the new system.

Rules:

- `amount` is always stored as a positive magnitude.
- Business direction is determined only by `entry_type`.
- API and DB validation must reject zero or negative amounts.
- standalone API-created ledger entries must persist `request_id` and `request_hash` for retry-safe idempotency
- invoice-driven ledger entries may leave `request_id` and `request_hash` null because the parent invoice already owns idempotency
- invoice-driven `CREDIT_SALE` entries must use the invoice's `invoice_date` as `occurred_on`
- invoice-driven `INVOICE_CANCEL_REVERSAL` entries must use the cancellation business date as `occurred_on`; in v1 this is the server-local current date at the time of successful cancellation unless an explicit cancel date is later added to the API
- manual `OPENING_BALANCE`, `PAYMENT`, `BALANCE_INCREASE_ADJUSTMENT`, and `BALANCE_DECREASE_ADJUSTMENT` entries must accept explicit `occurred_on` in the API request
- v1 allows backdated manual ledger entries for migration and bookkeeping accuracy
- enforce at most one `OPENING_BALANCE` entry per seller with a database-level partial unique index on `seller_id` where `entry_type = 'OPENING_BALANCE'`
- `CREDIT_SALE` and `INVOICE_CANCEL_REVERSAL` rows must have non-null `invoice_id`
- `OPENING_BALANCE`, `PAYMENT`, `BALANCE_INCREASE_ADJUSTMENT`, and `BALANCE_DECREASE_ADJUSTMENT` rows must have null `invoice_id`
- manual API-created rows must have non-null `request_id` and `request_hash`
- invoice-driven rows must have null `request_id` and `request_hash`
- enforce these invoice-link and idempotency-shape invariants with database `CHECK` constraints where practical

### 7. `stock_movements`

- `id UUID PRIMARY KEY`
- `product_id UUID NOT NULL REFERENCES products(id)`
- `invoice_id UUID NULL REFERENCES invoices(id)`
- `request_id UUID NULL UNIQUE`
- `request_hash TEXT NULL`
- `movement_type TEXT NOT NULL CHECK (movement_type IN ('OPENING', 'MANUAL_ADJUSTMENT', 'INVOICE_SALE', 'INVOICE_CANCEL_REVERSAL'))`
- `quantity_delta NUMERIC(14,3) NOT NULL CHECK (quantity_delta <> 0)`
- `reason TEXT NULL`
- `created_by_user_id UUID NOT NULL REFERENCES app_users(id)`
- `created_at TIMESTAMPTZ NOT NULL`

Rules:

- `INVOICE_SALE` movements must use negative `quantity_delta`.
- `INVOICE_CANCEL_REVERSAL` and `OPENING` movements must use positive `quantity_delta`.
- `MANUAL_ADJUSTMENT` may be positive or negative depending on correction direction.
- API and service validation must enforce these movement sign rules.
- standalone API-created stock adjustments must persist `request_id` and `request_hash` for retry-safe idempotency
- invoice-driven stock movements may leave `request_id` and `request_hash` null because the parent invoice already owns idempotency
- `INVOICE_SALE` and `INVOICE_CANCEL_REVERSAL` movements must have non-null `invoice_id`
- `OPENING` and `MANUAL_ADJUSTMENT` movements must have null `invoice_id`
- `MANUAL_ADJUSTMENT` rows must have non-null `request_id` and `request_hash`
- invoice-driven movement rows must have null `request_id` and `request_hash`
- enforce these invoice-link and idempotency-shape invariants with database `CHECK` constraints where practical

### Invoice Numbering

- Use a PostgreSQL sequence for stable invoice numbering.
- Never derive invoice numbers from row counts.

### Deletion Rules

- Products and sellers that are referenced by invoices or ledger transactions are archived rather than hard-deleted.
- Invoices and ledger entries are never hard-deleted in normal application flows.

## Ledger and Khata Rules

### Source Of Truth

- Seller balance is derived only from `seller_transactions`.
- There is no `seller.total_credit` or equivalent aggregate column.

### Behavior

- Every seller page shows:
  - seller profile
  - derived current pending balance
  - ledger transaction history
  - invoice history
- If an invoice is created with `payment_mode = CREDIT`, it creates a `CREDIT_SALE` ledger entry.
- If an invoice is created with `payment_mode = PAID`, it appears in invoice history but does not affect khata balance.
- Payments are seller-level only and are not allocated to specific invoices in v1.
- Opening balance is recorded as an explicit ledger transaction, not as a seller master field.

## Pricing And Tax Model

### Input Flexibility

- Invoice entry supports both `PRE_TAX` and `TAX_INCLUSIVE` price entry modes.

### Persistence Model

- Backend always normalizes line data before saving.
- Each persisted invoice item stores:
  - entry mode
  - entered unit price
  - normalized unit price before tax
  - normalized unit price after tax
  - GST rate
  - discount percent
  - discount amount
  - taxable amount
  - GST amount
  - final line total

### Rounding

- Use Python `Decimal` and PostgreSQL `NUMERIC`.
- Round monetary values at the line level using a single consistent policy such as `ROUND_HALF_UP`.
- Invoice totals are sums of stored line values.

## API Design

Return JSON only. Use consistent error envelopes and idempotent invoice creation.

### Authentication

- `POST /auth/login`
  - accepts username and password
  - returns short-lived access token and long-lived refresh token
- `POST /auth/refresh`
  - accepts refresh token
  - rotates and returns a new access token and refresh token pair
- `POST /auth/logout`
  - revokes the current refresh session
- `GET /auth/me`
  - returns current user profile

Rules:

- all business endpoints require bearer authentication except health and auth bootstrap endpoints if any
- all auth traffic must run over HTTPS in production

### Products

- `GET /products`
  - Filters: `company`, `category`, `search`, `active`, `low_stock_only`
- `POST /products`
- `GET /products/{product_id}`
- `PUT /products/{product_id}`
- `DELETE /products/{product_id}`
  - Archive only
- `POST /products/{product_id}/adjust-stock`
  - Creates a `MANUAL_ADJUSTMENT` stock movement and updates `quantity_on_hand` transactionally

Product create and edit rules:

- `POST /products` may set the initial `quantity_on_hand` only for brand new products.
- If initial stock is greater than zero, the backend must also create one `OPENING` stock movement in the same transaction.
- `PUT /products/{product_id}` must not directly rewrite stock as a blind field update.
- Any post-creation stock change must go through `POST /products/{product_id}/adjust-stock`.
- `POST /products/{product_id}/adjust-stock` must accept a client-generated `request_id` and be idempotent for the same normalized payload

### Sellers

- `GET /sellers`
  - Response includes derived `pending_balance`
- `POST /sellers`
- `GET /sellers/{seller_id}`
- `PUT /sellers/{seller_id}`
- `DELETE /sellers/{seller_id}`
  - Archive only
- `GET /sellers/{seller_id}/ledger`
  - Returns seller profile, derived balance, transactions, and invoice history

### Opening Balance And Payments

- `POST /sellers/{seller_id}/opening-balance`
  - Creates an `OPENING_BALANCE` ledger entry
- `POST /payments`
  - Creates a `PAYMENT` ledger entry
- `POST /sellers/{seller_id}/balance-adjustment`
  - Creates a manual audited ledger correction for rare admin use

Opening balance rules:

- `OPENING_BALANCE` is a one-time initialization entry per seller.
- The backend must reject creation if the seller already has an `OPENING_BALANCE` entry.
- Later corrections must go through the explicit balance adjustment endpoint, not repeated opening balances.
- the one-time rule must be enforced by both application validation and the database partial unique index

Retry safety rules:

- `POST /payments` must accept a client-generated `request_id` and be idempotent for the same normalized payload
- `POST /sellers/{seller_id}/opening-balance` must accept a client-generated `request_id` and be idempotent for the same normalized payload
- `POST /sellers/{seller_id}/balance-adjustment` must accept a client-generated `request_id` and be idempotent for the same normalized payload
- if the same `request_id` is reused with different payload content, backend must return `409 IDEMPOTENCY_CONFLICT`
- balance adjustment requests must include `direction = INCREASE | DECREASE`, and the backend persists the matching concrete entry type

Date rules:

- `POST /payments` must require `occurred_on`
- `POST /sellers/{seller_id}/opening-balance` must require `occurred_on`
- `POST /sellers/{seller_id}/balance-adjustment` must require `occurred_on`

### Invoices

- `POST /invoices/quote`
  - No writes
  - Normalizes item math, tax breakdown, and returns totals and stock warnings
  - Requires `place_of_supply_state_code` in the request unless it can be resolved from the seller record
- `POST /invoices`
  - Atomic and idempotent create
  - Requires `place_of_supply_state_code` in the request unless it can be resolved from the seller record
  - Returns the persisted invoice plus any stock warnings that applied at actual commit time
- `GET /invoices`
  - Filters: date range, seller, status, payment mode, invoice number
- `GET /invoices/{invoice_id}`
  - Returns invoice header, items, seller snapshot, and company snapshot captured at invoice creation time
- `POST /invoices/{invoice_id}/cancel`
  - Cancels invoice and reverses stock and credit effects
  - Must accept `request_id` and be idempotent for the same normalized payload

### Company Profile

- `GET /company-profile`
- `PUT /company-profile`

### Error Envelope

Use a consistent response shape for failures:

```json
{
  "error": {
    "code": "IDEMPOTENCY_CONFLICT",
    "message": "An invoice already exists for this request_id with different content"
  }
}
```

Suggested error codes:

- `VALIDATION_ERROR`
- `NOT_FOUND`
- `IDEMPOTENCY_CONFLICT`
- `INVOICE_ALREADY_CANCELED`
- `INVOICE_CREATE_FAILED`
- `PAYMENT_CREATE_FAILED`

## Atomic Invoice Creation

Invoice creation must occur in one database transaction.

### Required Flow

1. Begin transaction.
2. Validate seller and products.
3. Check whether `request_id` already exists.
4. Build a deterministic `request_hash` from the normalized request payload.
5. If an invoice already exists for the same `request_id` and same hash, return the existing invoice.
6. If an invoice already exists for the same `request_id` but a different hash, return `409 CONFLICT`.
7. Use a race-safe idempotency strategy:
   - either insert the invoice row only after acquiring a transaction-scoped advisory lock derived from `request_id`
   - or catch unique-constraint violation on `request_id`, re-read the existing invoice, and compare `request_hash`
8. Lock all referenced product rows using `SELECT ... FOR UPDATE` in deterministic `product_id` order.
9. Normalize line pricing and compute authoritative totals.
10. Capture seller and company snapshots for immutable invoice rendering.
11. Insert invoice header.
12. Insert invoice items.
13. Insert stock movement rows.
14. Update product stock quantities.
15. If `payment_mode = CREDIT`, insert a `CREDIT_SALE` seller transaction.
16. Collect stock warnings from the actual locked stock state and include them in the create response.
17. Commit.
18. If any step fails, roll back everything.

### Stock Rule

- Insufficient stock does not block invoice creation.
- The backend returns a warning.
- Stock can become negative after commit.
- `POST /invoices` success responses must include a `warnings` array so the client can display commit-time stock warnings, not just quote-time warnings.

### GST Snapshot Rule

- Invoice persistence must store enough tax information to re-render the exact historical invoice.
- For v1, the backend persists both total GST and explicit CGST, SGST, and IGST rates and amounts per line.
- `tax_regime` is stored on the invoice header.
- `tax_regime` is derived by the backend by comparing the active company profile `state_code` with the invoice `place_of_supply_state_code`.
- If `place_of_supply_state_code` is missing and cannot be resolved from seller data, quote and create requests must be rejected with `VALIDATION_ERROR`.
- If company profile state metadata is missing, quote and create requests must be rejected with `VALIDATION_ERROR` until company profile is completed.
- `place_of_supply_state` is derived by the backend from `place_of_supply_state_code` using a canonical state reference map and persisted alongside the code
- if seller data contains both state name and state code, backend must validate that they map to the same canonical state before using them
- PDF generation must use persisted tax breakdown fields only, not recompute split tax from current seller or company master data.

## Atomic Invoice Cancellation

Invoice cancellation must also be transactional.

### Required Flow

1. Begin transaction.
2. Lock invoice row.
3. Build a deterministic `cancel_request_hash` from the normalized cancel payload.
4. If the invoice is already canceled and `cancel_request_id` plus `cancel_request_hash` match the current request, return the already-canceled invoice as a success-equivalent idempotent response.
5. If the invoice is already canceled and the same `cancel_request_id` is reused with a different `cancel_request_hash`, return `409 IDEMPOTENCY_CONFLICT`.
6. If the invoice is already canceled from a different completed cancel request, return `409 INVOICE_ALREADY_CANCELED` with the current canceled invoice summary.
7. Lock referenced product rows in deterministic `product_id` order.
8. Mark invoice status as `CANCELED` and store `cancel_request_id`, `cancel_request_hash`, `cancel_reason`, `canceled_at`, and `canceled_by_user_id`.
9. Insert reversal stock movements.
10. Add quantities back to product stock.
11. If original payment mode was `CREDIT`, insert `INVOICE_CANCEL_REVERSAL` ledger entry.
12. Commit.

### Cancellation Rule

- No invoice editing is allowed.
- Correction path is always cancel and recreate.
- If a cancel request is retried with the same `request_id` and same payload, backend returns the already-canceled invoice as a success-equivalent idempotent response.
- If a different cancel `request_id` is used after cancellation is already completed, backend returns `409 INVOICE_ALREADY_CANCELED` with current canceled state.
- `cancel_reason` is part of the normalized cancel payload and therefore part of cancel idempotency matching.

## FastAPI Implementation Shape

### Technology

- FastAPI
- SQLAlchemy 2.0
- `psycopg`
- Alembic migrations
- Pydantic schemas
- Python `Decimal`

### Suggested Structure

- `app/main.py`
- `app/db.py`
- `app/auth.py`
- `app/models/`
- `app/schemas/`
- `app/routers/`
- `app/services/`
- `app/core/`
- `alembic/`

### Layering

- `routers`
  - HTTP parsing and response formatting
- `models`
  - ORM table definitions
- `schemas`
  - request and response DTOs
- `services`
  - transactional business workflows such as invoice creation, cancellation, payment creation, and opening balance creation
- `core/pricing.py`
  - pure pricing and tax normalization logic shared by quote and create flows

Additional shared modules:

- `core/idempotency.py`
  - canonical payload hashing rules for request replay safety
- `core/snapshots.py`
  - seller and company snapshot extraction for immutable invoice persistence

Additional note:

- payment creation, opening balance creation, and balance adjustment creation should reuse the same idempotency helper pattern as invoice creation

No repository layer is required for v1.

### PDF Strategy

- Generate PDFs only from persisted invoice data, invoice item snapshots, seller snapshot fields, and company snapshot fields captured at invoice creation time.
- Later edits to seller master data or company profile must not change historical invoice rendering.
- Tax rendering must use persisted `tax_regime`, `gst_rate`, `cgst_rate`, `sgst_rate`, `igst_rate`, and corresponding amount fields from the stored invoice snapshot.
- PDF file storage is not the source of truth.
- File caching can be added later if needed.

## Flutter Application Structure

Use a simple architecture: `UI -> Service -> Model`.

### Suggested Folder Structure

- `lib/auth/`
  - `auth_service.dart`
  - `session_store.dart`
  - `auth_guard.dart`
- `lib/models/`
  - `product.dart`
  - `seller.dart`
  - `seller_ledger.dart`
  - `invoice_draft.dart`
  - `invoice_detail.dart`
  - `company_profile.dart`
  - `api_error.dart`
- `lib/services/`
  - `api_client.dart`
  - `products_service.dart`
  - `sellers_service.dart`
  - `invoices_service.dart`
  - `payments_service.dart`
  - `company_profile_service.dart`
- `lib/screens/`
  - `login_screen.dart`
  - `inventory_list_screen.dart`
  - `product_form_screen.dart`
  - `seller_list_screen.dart`
  - `seller_detail_screen.dart`
  - `record_payment_screen.dart`
  - `create_invoice_screen.dart`
  - `invoice_preview_screen.dart`
- `lib/state/`
  - `invoice_draft_controller.dart`
- `lib/widgets/`
  - reusable pickers, tables, money inputs, and warning banners

### Screen Responsibilities

#### Inventory List

- Filter by company, category, or search text
- Show low-stock warnings
- Navigate to add or edit product

#### Product Form

- Create or update products

#### Seller List

- Search sellers
- Show derived pending balances
- Create seller

#### Seller Detail

- Show profile
- Show current pending balance
- Show ledger timeline
- Show invoice history
- Actions:
  - record payment
  - add opening balance
  - add balance adjustment
  - create invoice for this seller

#### Login

- Username and password sign-in
- Session restored from secure storage on app launch when refresh token is still valid
- User should not need to log in every time the app opens

#### Record Payment

- Create seller-level payment entry only

#### Create Invoice

- Seller is required
- Products come from live inventory
- Both price entry modes are supported
- Show stock warnings without blocking submit
- Quote API is used before final confirmation

#### Invoice Preview

- Shows server-calculated totals from quote response
- Final confirmation sends `POST /invoices`

### State Management

- Use `ChangeNotifier` or `ValueNotifier` for v1.
- Only the invoice draft requires local mutable state.
- Avoid overengineering or complex app-wide state frameworks unless growth later demands it.
- Keep auth state small and isolated: current user, token status, and session restore state.

## Failure Handling And Retry Safety

### Invoice Request ID Lifecycle

- Generate `request_id` when the user first confirms the invoice for save.
- Keep that same `request_id` attached to the draft until:
  - save succeeds
  - the draft is discarded
  - the user changes invoice content after failure

### Retry Rules

- If the network fails or the request times out, retry using the same `request_id`.
- If the invoice was already created, backend returns the existing invoice instead of creating a duplicate.
- If the same `request_id` is reused with changed content, backend returns `409`.
- The same retry rule also applies to payment creation, opening balance creation, and balance adjustment creation.
- The same retry rule also applies to stock adjustments and invoice cancellation.

### Request Hash Canonicalization

- `request_hash` must be generated from a canonical normalized payload.
- Canonicalization rules must include:
  - stable field ordering
  - normalized decimal string formatting
  - explicit inclusion of defaults such as `discount_percent = 0`
  - exclusion of derived totals that are recomputed by the backend
- Equivalent business payloads must always hash identically across retries.

### UI Rules On Failure

- Keep the draft intact when save fails.
- Show clear user-facing error messages.
- Do not adjust seller balances optimistically on the client.
- After invoice create, payment create, opening balance create, or invoice cancel, refresh the seller page from the API.
- After stock adjustment, refresh the product list or product detail from the API.
- If access token expires, refresh silently using the stored refresh token before forcing a visible re-login.

### Connectivity Rule

- Draft preparation can happen in screen state.
- Final save is blocked until the backend is reachable.
- There is no offline final invoice creation flow in v1.

## V1 Delivery Scope

### Backend

- Login, refresh, logout, and current-user APIs
- First-user bootstrap command or seed script
- Product CRUD
- Seller CRUD
- Seller opening balance entry
- Seller balance adjustment entry
- Payment entry
- Invoice quote
- Atomic invoice create
- Invoice list and detail
- Invoice cancel
- Company profile APIs

### Flutter Screens

- Login
- Inventory List
- Add or Edit Product
- Seller List
- Seller Detail
- Record Payment
- Add Opening Balance
- Add Balance Adjustment
- Create Invoice
- Invoice Preview

### Deferred From V1

- Analytics dashboards
- OCR import
- Spreadsheet bulk import
- Barcode scanning
- Multi-user roles
- Advanced PDF archival and file management
- Cloud sync complexity

## Testing Strategy

### Unit Tests

- Pricing normalization for both `PRE_TAX` and `TAX_INCLUSIVE`
- Discount calculations
- GST calculations
- Rounding behavior with `Decimal`
- Idempotency payload hash generation

### Integration Tests

- Successful login and token refresh
- Successful paid invoice creation
- Successful credit invoice creation
- Invoice creation rollback if any insert or update fails
- Same `request_id` plus same payload returns the existing invoice
- Same `request_id` plus different payload returns `409`
- Insufficient stock allowed and stock becomes negative
- Invoice cancellation restores stock
- Credit invoice cancellation inserts ledger reversal
- Payment creation reduces derived seller balance
- Opening balance appears correctly in seller ledger and seller balance
- Duplicate payment request with same `request_id` returns the original result without creating a second ledger row
- Duplicate opening balance request with same `request_id` returns the original result without creating a second ledger row
- Duplicate balance adjustment request with same `request_id` returns the original result without creating a second ledger row
- Duplicate stock adjustment request with same `request_id` returns the original result without creating a second movement row
- Duplicate cancel request with same `request_id` returns the original canceled invoice without applying reversal twice
- Only one active company profile exists
- Invoice detail and PDF preserve original line order
- Invoice detail and PDF preserve original persisted GST breakup
- Concurrent invoice creation and cancellation on overlapping products do not corrupt stock or deadlock under deterministic locking

## Migration And Data Import Guardrails

- Legacy previous balances are imported as `OPENING_BALANCE` ledger entries.
- Legacy credit invoices are imported as `CREDIT_SALE` entries.
- Legacy payment rows are imported as `PAYMENT` entries.
- Legacy invoice JSON items must be mapped into `invoice_items` rows.
- Invalid legacy rows must be rejected into an import error report instead of being silently inserted.
- Do not carry forward old schema drift or duplicated balance update logic.

## Operational Safety Rules

- Schedule PostgreSQL backups from day one.
- Store audit fields such as `created_at`, `occurred_on`, `cancel_reason`, and `canceled_at`.
- Use `NUMERIC` and `Decimal` for all money values, never floats.
- No hard-delete for referenced financial records.
- Use secure password hashing for app users.
- Store refresh tokens only as hashes on the backend and in secure storage on the mobile app.
- Serve the API only over HTTPS in production.
- Record the acting user on invoice creation, invoice cancellation, seller ledger adjustments, payments, opening balances, and stock movements.

## Final Outcome

This design produces a production-grade internal billing and khata system that preserves the strongest parts of the current app while fixing the major data integrity problems:

- normalized invoice items instead of JSON blobs
- authoritative transaction-based khata
- explicit opening balance support for backward compatibility
- atomic invoice creation and cancellation
- safe idempotent retries
- simple mobile architecture with backend-owned correctness
