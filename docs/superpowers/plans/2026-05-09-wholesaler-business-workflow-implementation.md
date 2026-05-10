# Wholesaler Business Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current offline-first billing app into a usable small-wholesaler workflow with robust inventory CRUD, supplier/buyer ledger, customer khata, improved invoice creation, analytics, and aligned local/server data models.

**Architecture:** Use one canonical business model across Drift/local mode and FastAPI/Postgres server mode. Keep local and server tables/API DTOs structurally aligned so data can move from local to server or into hybrid sync later. Use append-only ledgers for customer receivables and buyer/supplier payables; compute balances from transactions rather than storing mutable balance as source of truth.

**Tech Stack:** Flutter, Drift/SQLite, FastAPI, SQLAlchemy/Postgres, Alembic migrations, existing service/controller patterns, widget/service tests, backend API/service tests.

**Plan Style:** This plan intentionally contains no code snippets per user request. Each task lists exact files, behavior, tests, verification commands, and commit boundaries.

---

## Approved Business Decisions

- Buyer/Supplier means the company, brand, or party we purchase goods from.
- Inventory `company_name` maps to Buyer/Supplier for analytics and future migration.
- Buyer/Supplier ledger is money-only for now and does not automatically update inventory stock.
- Current Seller tab will be renamed to Customers/Khata because these are customers who buy from us.
- Every invoice enters the full invoice amount into customer khata.
- `TOTAL_PAID` and `PARTIAL_PAID` create immediate collection entries against that same invoice.
- Invoice line prices default to price-includes-GST.
- Invoice line price must be editable per invoice because different customers can get different rates.
- Invoice GST defaults from the product line but can be overridden per line. Add an invoice-wide “apply GST to all lines” convenience control rather than a separate bill-level tax model in the first pass.
- Product quick-add and customer quick-add must be available from invoice creation.
- Date/time should be visible and editable on invoices and ledger inputs, defaulting to now.

---

## File Structure

### Backend

- Modify `backend/app/models/product.py`: canonical inventory fields and buyer reference.
- Create `backend/app/models/buyer.py`: Buyer/Supplier entity.
- Create `backend/app/models/buyer_transaction.py`: Buyer payable ledger.
- Create `backend/app/models/customer.py`: Customer/Khata entity replacing seller terminology.
- Create `backend/app/models/customer_transaction.py`: Customer receivable ledger replacing seller transaction terminology.
- Modify `backend/app/models/invoice.py`: payment state, invoice datetime, customer references, buyer/company snapshots.
- Modify `backend/app/models/invoice_item.py`: item number, buying price snapshot, selling price snapshot, unit, GST inclusive pricing snapshots.
- Modify or replace `backend/app/models/seller.py` and `backend/app/models/seller_transaction.py`: migrate or alias to customer naming.
- Create Alembic migration under `backend/alembic/versions/` for buyer/customer/product/invoice schema changes.
- Create `backend/app/schemas/buyer.py`: Buyer API DTOs.
- Create or rename `backend/app/schemas/customer.py`: Customer/Khata API DTOs.
- Modify `backend/app/schemas/product.py`: inventory V2 DTOs.
- Modify `backend/app/schemas/invoice.py`: invoice V2 DTOs.
- Create `backend/app/schemas/analytics.py`: analytics response DTOs.
- Create `backend/app/services/buyer_service.py`: Buyer ledger behavior.
- Create or rename `backend/app/services/customer_service.py`: Customer/Khata behavior.
- Modify `backend/app/services/product_service.py`: inventory V2 validation and CRUD.
- Modify `backend/app/services/invoice_service.py`: invoice V2 pricing, payment states, snapshots, ledger side effects.
- Create `backend/app/services/analytics_service.py`: revenue/profit/khata/payable queries.
- Create `backend/app/routers/buyers.py`: Buyer API routes.
- Create or rename `backend/app/routers/customers.py`: Customer/Khata API routes.
- Modify `backend/app/routers/products.py`: inventory V2 routes.
- Modify `backend/app/routers/invoices.py`: invoice V2 routes.
- Create `backend/app/routers/analytics.py`: analytics routes.
- Modify `backend/app/main.py`: include new routers.
- Modify backend tests under `backend/tests/api/` and `backend/tests/services/`.

### Mobile Shared Models And Services

- Modify `mobile/lib/models/product.dart`: inventory V2 fields.
- Create `mobile/lib/models/buyer.dart`: Buyer/Supplier model.
- Create `mobile/lib/models/buyer_ledger.dart`: Buyer ledger models.
- Create or rename `mobile/lib/models/customer.dart`: Customer/Khata model.
- Create or rename `mobile/lib/models/customer_ledger.dart`: Customer ledger models.
- Modify `mobile/lib/models/invoice_draft.dart`: quick-add, editable line price/GST, payment state, date/time.
- Modify `mobile/lib/models/invoice_quote.dart`: inclusive GST totals and profit snapshots.
- Modify `mobile/lib/models/invoice_detail.dart`: invoice V2 fields.
- Modify `mobile/lib/models/invoice_summary.dart`: payment state and customer fields.
- Create `mobile/lib/models/analytics.dart`: analytics dashboard models.
- Modify `mobile/lib/services/products_service.dart`: inventory V2 API contract.
- Create `mobile/lib/services/buyers_service.dart`: Buyer API/local contract.
- Create or rename `mobile/lib/services/customers_service.dart`: Customer/Khata API/local contract.
- Modify `mobile/lib/services/payments_service.dart`: customer collection/adjustment naming.
- Modify `mobile/lib/services/invoices_service.dart`: invoice V2 API contract.
- Create `mobile/lib/services/analytics_service.dart`: analytics API/local contract.

### Mobile Local Mode

- Modify `mobile/lib/local/local_database.dart`: schemaVersion bump and migrations for product/customer/buyer/invoice V2.
- Modify `mobile/lib/local/local_database.g.dart`: regenerated Drift code.
- Modify `mobile/lib/local/local_products_service.dart`: inventory V2 CRUD and validation.
- Create `mobile/lib/local/local_buyers_service.dart`: Buyer ledger implementation.
- Create or rename `mobile/lib/local/local_customers_service.dart`: Customer/Khata implementation.
- Modify `mobile/lib/local/local_payments_service.dart`: customer ledger naming and math.
- Modify `mobile/lib/local/local_invoices_service.dart`: invoice V2 behavior.
- Create `mobile/lib/local/local_analytics_service.dart`: local analytics queries.
- Modify `mobile/lib/backup/local_backup_service.dart`: backup payload V2, table allowlist updates.

### Mobile UI

- Modify `mobile/lib/main.dart`: navigation and dependency wiring.
- Modify `mobile/lib/widgets/app_navigation_drawer.dart`: rename Seller to Customers/Khata, add Buyer and Analytics destinations.
- Modify `mobile/lib/screens/inventory_list_screen.dart`: inventory CRUD UX.
- Modify `mobile/lib/screens/product_form_screen.dart`: product V2 form.
- Create `mobile/lib/screens/product_detail_screen.dart`: view/edit/archive/stock actions.
- Create `mobile/lib/screens/buyer_list_screen.dart`: Buyer tab.
- Create `mobile/lib/screens/buyer_form_screen.dart`: add/edit buyer.
- Create `mobile/lib/screens/buyer_detail_screen.dart`: buyer ledger and payable balance.
- Create or rename `mobile/lib/screens/customer_list_screen.dart`: Customers/Khata list.
- Create or rename `mobile/lib/screens/customer_detail_screen.dart`: invoices, collections, adjustments, date-wise ledger.
- Modify `mobile/lib/screens/create_invoice_screen.dart`: invoice V2 editor.
- Modify `mobile/lib/screens/invoice_preview_screen.dart`: invoice V2 preview.
- Modify `mobile/lib/screens/invoice_list_screen.dart`: invoice V2 list filters.
- Create reusable `mobile/lib/screens/product_quick_add_dialog.dart`: quick add product from invoice.
- Create reusable `mobile/lib/screens/customer_quick_add_dialog.dart`: quick add customer from invoice.
- Create `mobile/lib/screens/analytics_screen.dart`: analytics dashboard.
- Add or modify widget tests under `mobile/test/widgets/`, `mobile/test/app/`, and `mobile/test/local/`.

---

## Task 1: Create Feature Branch And Verify Baseline

**Files:**
- No production file changes.

- [ ] **Step 1: Start from the offline-first branch**
  - Work from `feature/offline-first-local-mode` or a new branch based on it, for example `feature/wholesaler-business-workflow`.
  - Confirm the branch contains local mode, Drift schema, local services, backup, and scheduler work.
  - Run `git status --short` and ensure only intentional changes are present.

- [ ] **Step 2: Run baseline mobile tests**
  - Run `(cd mobile && flutter test test -r expanded)`.
  - Expected result: all tests pass before changing behavior.
  - If tests fail, stop and fix baseline before starting feature work.

- [ ] **Step 3: Run baseline backend tests**
  - Run backend tests with the dedicated test database command from `backend/agent.md`.
  - Expected result: backend tests pass or existing environment blocker is documented.

- [ ] **Step 4: Capture local APK issue before fixing**
  - Build local-mode release APK with `(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)`.
  - Install on emulator or device.
  - Attempt fresh local first-user setup and sign-in.
  - Attempt Add Product from Inventory.
  - Capture exact visible error, console logs, and `adb logcat` excerpt if either flow fails.

- [ ] **Step 5: Commit only if test harness or docs changed**
  - If no files changed, do not commit.
  - If a baseline reproduction note is added, commit with `docs: record wholesaler workflow baseline`.

---

## Task 2: Stabilize Local Release Sign-In And Add Product

**Files:**
- Modify as needed: `mobile/lib/main.dart`
- Modify as needed: `mobile/lib/app/app_dependencies.dart`
- Modify as needed: `mobile/lib/auth/session_store.dart`
- Modify as needed: `mobile/lib/screens/local_first_user_setup_screen.dart`
- Modify as needed: `mobile/lib/screens/login_screen.dart`
- Modify as needed: `mobile/lib/screens/inventory_list_screen.dart`
- Modify as needed: `mobile/lib/screens/product_form_screen.dart`
- Test: `mobile/test/app/local_mode_app_test.dart`
- Test: `mobile/test/widgets/product_form_screen_test.dart`
- Test: `mobile/test/local/local_products_service_test.dart`

- [ ] **Step 1: Add a failing local release-equivalent widget test**
  - Test starts `BillingApp` with local dependencies and persistent in-memory session store.
  - Test creates first local user.
  - Test signs in with that user.
  - Test reaches Inventory.
  - Test taps Add Product.
  - Test fills required product fields.
  - Test saves product and sees it in Inventory.
  - Expected pre-fix result: reproduces the current local sign-in or add-product failure.

- [ ] **Step 2: Add a focused product form validation test**
  - Test empty required fields show user-friendly validation instead of saving zero/blank values.
  - Test valid fields submit `item_number`, `item_name`, `category`, `company_name`, selling price, buying price, GST, optional unit, and quantity.
  - Expected pre-fix result: missing fields or current product model gaps fail.

- [ ] **Step 3: Fix root cause only after reproduction**
  - If the failure is `DATA_MODE` wiring, fix app dependency creation and add coverage.
  - If the failure is local setup/login state, fix setup-to-login transition and session restore.
  - If the failure is product form validation/schema mismatch, fix product form and local product service.
  - Do not begin full Inventory V2 until this stabilization path works.

- [ ] **Step 4: Verify local APK path manually**
  - Run `(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)`.
  - Install the APK on emulator or mobile.
  - Fresh app data should show local setup.
  - Setup, sign-in, Add Product, and list refresh should work.

- [ ] **Step 5: Run regression tests**
  - Run `(cd mobile && flutter test test/app/local_mode_app_test.dart test/widgets/product_form_screen_test.dart test/local/local_products_service_test.dart -r expanded)`.
  - Run `(cd mobile && flutter test test -r expanded)`.

- [ ] **Step 6: Commit**
  - Commit with `fix: stabilize local mode sign in and product creation`.

---

## Task 3: Define Canonical Schema Names And Migration Strategy

**Files:**
- Modify: `docs/superpowers/plans/2026-05-09-wholesaler-business-workflow-implementation.md` if discoveries require plan adjustments.
- Create: `docs/superpowers/specs/2026-05-09-canonical-wholesaler-schema.md`
- Modify: `backend/app/models/` model references only after tests exist in later tasks.
- Modify: `mobile/lib/local/local_database.dart` only after tests exist in later tasks.

- [ ] **Step 1: Write schema contract document**
  - Document canonical table names: `buyers`, `buyer_transactions`, `customers`, `customer_transactions`, `products`, `stock_movements`, `invoices`, `invoice_items`, `company_profiles`, `local_users`, `local_sessions`, `backup_settings`, `backup_events`.
  - Document canonical product fields: `id`, `item_number`, `item_name`, `category`, `buyer_id`, `company_name`, `buying_price`, `selling_price`, `unit`, `gst_rate`, `quantity_on_hand`, `low_stock_threshold`, `is_active`, timestamps.
  - Document canonical buyer ledger fields and entry types.
  - Document canonical customer ledger fields and entry types.
  - Document invoice payment states: `CREDIT`, `TOTAL_PAID`, `PARTIAL_PAID`.
  - Document inclusive GST math and invoice snapshot fields.

- [ ] **Step 2: Decide migration naming**
  - Treat current `sellers` as `customers` in the new schema.
  - Treat current `seller_transactions` as `customer_transactions`.
  - Treat current product `item_code` as new `item_number`.
  - Treat current product `company` as new `company_name` and link it to `buyers.name`.

- [ ] **Step 3: Decide compatibility policy**
  - Backend should expose new `/customers` routes.
  - Mobile should use new customer naming everywhere.
  - Existing `/sellers` routes may remain as temporary aliases only if needed to keep current backend tests green during migration.
  - Local Drift schema should bump to schemaVersion 2 and migrate existing test-device local DBs.

- [ ] **Step 4: Self-review schema contract**
  - Confirm every mobile local table has a matching backend/Postgres concept.
  - Confirm every decimal field has exact local and server representations.
  - Confirm every ledger balance is computed from transactions.

- [ ] **Step 5: Commit**
  - Commit with `docs: define canonical wholesaler schema`.

---

## Task 4: Backend Product Schema V2

**Files:**
- Modify: `backend/app/models/product.py`
- Modify: `backend/app/schemas/product.py`
- Modify: `backend/app/services/product_service.py`
- Modify: `backend/app/routers/products.py`
- Create: `backend/alembic/versions/<revision>_product_schema_v2.py`
- Test: `backend/tests/services/test_product_service.py`
- Test: `backend/tests/api/test_products.py` or create if absent.

- [ ] **Step 1: Write failing backend service tests**
  - Test product create requires `item_number`, `item_name`, `category`, `company_name`, `buying_price`, `selling_price`, and `gst_rate`.
  - Test `unit` can be null.
  - Test duplicate `item_number` is rejected.
  - Test duplicate `(company_name, item_name, category)` is rejected.
  - Test update changes editable fields without changing quantity unless stock adjustment is used.
  - Test archive/delete marks product inactive.

- [ ] **Step 2: Write failing backend API tests**
  - Test create/list/search/filter uses new field names.
  - Test API response includes buying price, selling price, unit, GST, quantity, and active flag.
  - Test old `item_code` is not required in new API payloads.

- [ ] **Step 3: Add Alembic migration**
  - Rename or add `item_number` from existing `item_code`.
  - Rename or add `company_name` from existing `company`.
  - Add nullable `buyer_id` until Buyer task links existing products.
  - Add `buying_price`, `selling_price`, `unit`, and `gst_rate` fields if missing.
  - Preserve existing IDs and quantities.

- [ ] **Step 4: Update backend model and service**
  - Enforce canonical uniqueness at database and service level.
  - Keep exact decimal types for prices, GST, and quantity.
  - Keep stock movement as the source of stock history.

- [ ] **Step 5: Verify backend product behavior**
  - Run product service tests.
  - Run product API tests.
  - Run full backend tests if environment is available.

- [ ] **Step 6: Commit**
  - Commit with `feat: add backend product schema v2`.

---

## Task 5: Mobile Product Schema V2 And Local Migration

**Files:**
- Modify: `mobile/lib/models/product.dart`
- Modify: `mobile/lib/services/products_service.dart`
- Modify: `mobile/lib/local/local_database.dart`
- Modify: `mobile/lib/local/local_database.g.dart`
- Modify: `mobile/lib/local/local_products_service.dart`
- Modify: `mobile/lib/backup/local_backup_service.dart`
- Test: `mobile/test/local/local_database_test.dart`
- Test: `mobile/test/local/local_products_service_test.dart`
- Test: `mobile/test/backup/local_backup_service_test.dart`

- [ ] **Step 1: Write failing Drift schema tests**
  - Test products table has canonical V2 fields.
  - Test `unit` is nullable.
  - Test `item_number` is unique.
  - Test `(company_name, item_name, category)` is unique.
  - Test schemaVersion increments to 2.

- [ ] **Step 2: Write failing local product service tests**
  - Test create stores buying price, selling price, GST, optional unit, and item number.
  - Test duplicate item number is rejected.
  - Test duplicate company/name/category is rejected.
  - Test archive hides products only when active filter is explicitly used.
  - Test stock quantity remains accurate after update.

- [ ] **Step 3: Update product model and service contracts**
  - Replace `itemCode` with `itemNumber` in mobile model and service inputs.
  - Replace `company` with `companyName` in UI-facing model, while still allowing buyer linkage later.
  - Add `buyingPrice`, `sellingPrice`, `unit`, and `gstRate`.

- [ ] **Step 4: Implement Drift migration**
  - Add V2 fields and migrate data from current fields.
  - Preserve existing product IDs.
  - Keep decimal strings exact.
  - Keep backup compatibility by bumping backup payload version if needed.

- [ ] **Step 5: Verify local product behavior**
  - Run local database tests.
  - Run local products service tests.
  - Run backup round-trip tests.

- [ ] **Step 6: Commit**
  - Commit with `feat: add mobile product schema v2`.

---

## Task 6: Inventory CRUD UX V2

**Files:**
- Modify: `mobile/lib/screens/inventory_list_screen.dart`
- Modify: `mobile/lib/screens/product_form_screen.dart`
- Create: `mobile/lib/screens/product_detail_screen.dart`
- Modify: `mobile/lib/main.dart`
- Test: `mobile/test/widgets/inventory_list_screen_test.dart`
- Test: `mobile/test/widgets/product_form_screen_test.dart`
- Test: `mobile/test/widgets/product_detail_screen_test.dart`
- Test: `mobile/test/app/local_mode_app_test.dart`

- [ ] **Step 1: Write failing inventory list tests**
  - Test Inventory shows Add Product button.
  - Test list rows show item number, item name, company/buyer, category, stock, selling price, GST, and active/archived status.
  - Test search filters by item number and item name.
  - Test filter by company and category.
  - Test tapping a product opens detail screen.

- [ ] **Step 2: Write failing product form tests**
  - Test required fields: item number, item name, category, company/buyer, buying price, selling price, GST.
  - Test unit is optional.
  - Test blank or invalid prices show clear validation.
  - Test save returns a product and refreshes inventory.

- [ ] **Step 3: Write failing product detail tests**
  - Test detail shows all inventory fields.
  - Test Edit opens the form.
  - Test Archive/Delete marks product inactive.
  - Test archived products cannot be added to new invoices unless explicitly reactivated.
  - Test stock adjustment updates quantity with a stock movement record.

- [ ] **Step 4: Implement UX**
  - Use simple Material layout with clear sections.
  - Keep form usable on mobile screens with scrolling and numeric keyboards.
  - Show clear success/error messages.
  - Avoid dense spreadsheet UI for first pass.

- [ ] **Step 5: Verify local APK flow**
  - Build local-mode APK.
  - Install and manually test Add/Edit/Archive/Stock Adjustment on emulator or phone.

- [ ] **Step 6: Run tests and commit**
  - Run focused widget tests.
  - Run full mobile tests.
  - Commit with `feat: add inventory crud ux v2`.

---

## Task 7: Backend Buyer/Supplier Ledger

**Files:**
- Create: `backend/app/models/buyer.py`
- Create: `backend/app/models/buyer_transaction.py`
- Create: `backend/app/schemas/buyer.py`
- Create: `backend/app/services/buyer_service.py`
- Create: `backend/app/routers/buyers.py`
- Modify: `backend/app/main.py`
- Create: `backend/alembic/versions/<revision>_add_buyers.py`
- Test: `backend/tests/services/test_buyer_service.py`
- Test: `backend/tests/api/test_buyers.py`

- [ ] **Step 1: Write failing buyer service tests**
  - Test create buyer with name and optional contact fields.
  - Test duplicate buyer name/phone behavior is deterministic.
  - Test opening pending amount creates an opening ledger entry.
  - Test purchase amount increases payable balance.
  - Test payment made decreases payable balance.
  - Test adjustments increase/decrease payable balance.
  - Test ledger is ordered by occurred date/time then created time.

- [ ] **Step 2: Write failing buyer API tests**
  - Test create/list/search buyers.
  - Test buyer detail includes computed pending payable.
  - Test add purchase amount endpoint.
  - Test add payment made endpoint.
  - Test add adjustment endpoints.

- [ ] **Step 3: Implement database model and migration**
  - Add `buyers` table.
  - Add `buyer_transactions` table.
  - Use decimal numeric columns for amounts.
  - Use append-only ledger rows.

- [ ] **Step 4: Implement service and router**
  - Compute balance from ledger rows.
  - Validate positive amounts.
  - Validate dates.
  - Use request IDs for retry-safe writes where existing backend patterns require it.

- [ ] **Step 5: Verify and commit**
  - Run buyer service/API tests.
  - Run full backend tests.
  - Commit with `feat: add backend buyer ledger`.

---

## Task 8: Mobile Buyer/Supplier Ledger

**Files:**
- Create: `mobile/lib/models/buyer.dart`
- Create: `mobile/lib/models/buyer_ledger.dart`
- Create: `mobile/lib/services/buyers_service.dart`
- Create: `mobile/lib/local/local_buyers_service.dart`
- Modify: `mobile/lib/local/local_database.dart`
- Modify: `mobile/lib/local/local_database.g.dart`
- Modify: `mobile/lib/app/app_dependencies.dart`
- Modify: `mobile/lib/widgets/app_navigation_drawer.dart`
- Modify: `mobile/lib/main.dart`
- Create: `mobile/lib/screens/buyer_list_screen.dart`
- Create: `mobile/lib/screens/buyer_form_screen.dart`
- Create: `mobile/lib/screens/buyer_detail_screen.dart`
- Test: `mobile/test/local/local_buyers_service_test.dart`
- Test: `mobile/test/widgets/buyer_screens_test.dart`

- [ ] **Step 1: Write failing local buyer service tests**
  - Test create buyer.
  - Test list/search buyers.
  - Test opening pending amount.
  - Test purchase amount.
  - Test payment made.
  - Test balance adjustments.
  - Test payable balance math.
  - Test ledger ordering.

- [ ] **Step 2: Write failing buyer UI tests**
  - Test drawer shows Buyer tab.
  - Test Buyer list loads.
  - Test Add Buyer flow.
  - Test Buyer detail shows payable balance and ledger rows.
  - Test add purchase amount, payment made, and adjustment forms.

- [ ] **Step 3: Implement local database and service**
  - Add Drift buyer and buyer transaction tables if not already present.
  - Keep amounts as decimal strings locally.
  - Compute payable from transaction rows.

- [ ] **Step 4: Implement UI**
  - Keep screens simple: list, detail, action buttons, forms.
  - Use date/time defaults and visible date controls.
  - Show clear labels: Purchase Amount, Payment Made, Pending Payable.

- [ ] **Step 5: Wire API/local dependencies**
  - Add `BuyersService` to `AppDependencies`.
  - Use API service in server mode and local service in local mode.

- [ ] **Step 6: Verify and commit**
  - Run buyer service and UI tests.
  - Run full mobile tests.
  - Commit with `feat: add buyer ledger to mobile`.

---

## Task 9: Rename Seller To Customers/Khata

**Files:**
- Backend modify or create customer equivalents for seller files.
- Mobile rename or wrap seller models/services/screens to customer naming.
- Modify: `mobile/lib/widgets/app_navigation_drawer.dart`
- Modify: `mobile/lib/main.dart`
- Modify docs: `README.md`, `mobile/agent.md`, `backend/agent.md`
- Test: backend customer service/API tests.
- Test: mobile customer/khata widget and local service tests.

- [ ] **Step 1: Write failing terminology tests**
  - Mobile drawer should show `Customers/Khata`, not `Sellers`.
  - Customer screens should use customer/khata labels.
  - Backend customer API should expose customer naming.

- [ ] **Step 2: Write failing customer ledger parity tests**
  - Existing seller ledger behavior should still work under customer naming.
  - Opening balance, collection received, and adjustments should compute the same balance as before.
  - Ledger should be date-wise and ordered deterministically.

- [ ] **Step 3: Migrate backend naming**
  - Add customer models/routes/services or rename seller equivalents.
  - Migrate database tables from seller naming to customer naming if chosen in Task 3.
  - Keep temporary aliases only if needed to keep existing routes/tests stable during transition.

- [ ] **Step 4: Migrate mobile naming**
  - Rename UI text and navigation first.
  - Rename model/service files if the change is not too disruptive.
  - Keep old internal names temporarily only if required to keep task size manageable.

- [ ] **Step 5: Verify and commit**
  - Run backend tests.
  - Run mobile tests.
  - Commit with `feat: rename sellers to customers khata`.

---

## Task 10: Customer/Khata Ledger Hardening

**Files:**
- Modify customer service/backend equivalent.
- Modify local customer/payments service equivalent.
- Modify customer detail screen.
- Test backend customer ledger service.
- Test mobile local customer ledger.
- Test customer detail widgets.

- [ ] **Step 1: Write ledger math tests**
  - Opening balance increases receivable.
  - Invoice sale increases receivable.
  - Collection received decreases receivable.
  - Balance increase adjustment increases receivable.
  - Balance decrease adjustment decreases receivable.
  - Cancel invoice reversal reduces receivable.
  - Balance never depends on stored mutable total.

- [ ] **Step 2: Write date-wise ledger tests**
  - Ledger groups or filters by date.
  - Date picker defaults to today.
  - Ledger rows store date/time.
  - Same-day multiple collections sort predictably.

- [ ] **Step 3: Implement service hardening**
  - Validate positive amounts.
  - Validate date/time strings.
  - Validate request IDs where exposed.
  - Keep append-only transaction rows.

- [ ] **Step 4: Improve customer detail UX**
  - Show balance at top.
  - Show quick action to collect money.
  - Show increase/decrease adjustment actions.
  - Show invoice history and ledger history clearly.

- [ ] **Step 5: Verify and commit**
  - Run focused ledger tests.
  - Run full mobile/backend test suites.
  - Commit with `fix: harden customer khata ledger`.

---

## Task 11: Backend Invoice V2 Domain

**Files:**
- Modify: `backend/app/models/invoice.py`
- Modify: `backend/app/models/invoice_item.py`
- Modify: `backend/app/schemas/invoice.py`
- Modify: `backend/app/services/invoice_service.py`
- Modify: `backend/app/routers/invoices.py`
- Create: `backend/alembic/versions/<revision>_invoice_v2.py`
- Test: `backend/tests/services/test_invoice_service.py`
- Test: `backend/tests/api/test_invoices.py`

- [ ] **Step 1: Write failing quote tests**
  - Quote uses selling price inclusive of GST by default.
  - Quote can override line selling price.
  - Quote can override line GST rate.
  - Quote snapshots product item number, item name, category, buyer/company, buying price, selling price, GST, and unit.
  - Quote calculates revenue and profit inputs correctly.

- [ ] **Step 2: Write failing create tests**
  - Create invoice with `CREDIT` debits full amount to customer khata.
  - Create invoice with `TOTAL_PAID` debits full amount and creates full collection entry.
  - Create invoice with `PARTIAL_PAID` debits full amount and creates partial collection entry.
  - Create reduces inventory stock by sold quantities.
  - Create stores invoice datetime.

- [ ] **Step 3: Write failing cancel tests**
  - Cancel restores stock.
  - Cancel reverses customer khata entries.
  - Cancel is idempotent according to request ID behavior.

- [ ] **Step 4: Implement migration and domain logic**
  - Add payment state and paid amount fields.
  - Add invoice datetime field.
  - Add invoice item snapshot fields.
  - Keep invoice number unique and ordered.
  - Keep all side effects transactional.

- [ ] **Step 5: Verify and commit**
  - Run backend invoice service/API tests.
  - Run full backend tests.
  - Commit with `feat: add backend invoice v2 domain`.

---

## Task 12: Mobile Local Invoice V2 Service

**Files:**
- Modify: `mobile/lib/models/invoice_draft.dart`
- Modify: `mobile/lib/models/invoice_quote.dart`
- Modify: `mobile/lib/models/invoice_detail.dart`
- Modify: `mobile/lib/models/invoice_summary.dart`
- Modify: `mobile/lib/services/invoices_service.dart`
- Modify: `mobile/lib/local/local_invoices_service.dart`
- Modify: `mobile/lib/local/local_database.dart`
- Modify: `mobile/lib/local/local_database.g.dart`
- Test: `mobile/test/local/local_invoices_service_test.dart`

- [ ] **Step 1: Write failing local quote tests**
  - Quote uses line selling price inclusive of GST.
  - Quote allows edited selling price.
  - Quote allows edited line GST rate.
  - Quote stores product/buyer/company snapshots.
  - Quote supports optional unit.

- [ ] **Step 2: Write failing local create tests**
  - `CREDIT` creates full customer khata debit.
  - `TOTAL_PAID` creates full debit and full collection.
  - `PARTIAL_PAID` creates full debit and partial collection.
  - Stock reduces correctly for repeated products.
  - Invoice datetime is stored.

- [ ] **Step 3: Write failing local cancel tests**
  - Cancel restores stock.
  - Cancel reverses customer ledger rows.
  - Cancel does not duplicate reversal rows.

- [ ] **Step 4: Implement local invoice V2**
  - Keep all create/cancel side effects inside Drift transactions.
  - Keep decimal values as exact text strings.
  - Keep invoice item snapshots immutable.

- [ ] **Step 5: Verify and commit**
  - Run local invoice tests.
  - Run full mobile tests.
  - Commit with `feat: add local invoice v2 service`.

---

## Task 13: Invoice Creation UX V2

**Files:**
- Modify: `mobile/lib/screens/create_invoice_screen.dart`
- Modify: `mobile/lib/screens/invoice_preview_screen.dart`
- Create: `mobile/lib/screens/product_quick_add_dialog.dart`
- Create: `mobile/lib/screens/customer_quick_add_dialog.dart`
- Modify: `mobile/lib/state/invoice_draft_controller.dart`
- Test: `mobile/test/widgets/create_invoice_screen_test.dart`
- Test: `mobile/test/widgets/invoice_preview_screen_test.dart`

- [ ] **Step 1: Write failing invoice UI tests**
  - Test customer selection.
  - Test quick-add customer popup.
  - Test product selection.
  - Test quick-add product popup.
  - Test editable selling price per line.
  - Test editable GST per line.
  - Test invoice-wide “apply GST to all lines” control.
  - Test payment state selection: Credit, Total Paid, Partial Paid.
  - Test partial paid amount field appears only for Partial Paid.
  - Test visible date/time picker defaults to now.

- [ ] **Step 2: Write failing preview tests**
  - Preview shows item name, item number, category, unit/quantity, price per unit, line total.
  - Preview shows inclusive GST totals.
  - Preview shows payment state and paid amount.
  - Preview hides internal cost/buying price from invoice view.

- [ ] **Step 3: Implement UI in small sections**
  - First customer selection and quick-add.
  - Then product selection and quick-add.
  - Then editable line price/GST.
  - Then payment state.
  - Then date/time picker.

- [ ] **Step 4: Verify on mobile layout**
  - Test in narrow mobile viewport.
  - Ensure no overflow.
  - Ensure keyboard does not hide primary action permanently.

- [ ] **Step 5: Verify and commit**
  - Run invoice widget tests.
  - Run full mobile tests.
  - Commit with `feat: redesign invoice creation workflow`.

---

## Task 14: Backend Analytics

**Files:**
- Create: `backend/app/schemas/analytics.py`
- Create: `backend/app/services/analytics_service.py`
- Create: `backend/app/routers/analytics.py`
- Modify: `backend/app/main.py`
- Test: `backend/tests/services/test_analytics_service.py`
- Test: `backend/tests/api/test_analytics.py`

- [ ] **Step 1: Write failing analytics service tests**
  - Test revenue by buyer/company.
  - Test profit by buyer/company using invoice item buying price snapshot.
  - Test revenue by customer.
  - Test outstanding customer khata balance.
  - Test buyer pending payable.
  - Test top products by quantity, revenue, and profit.
  - Test low stock summary.
  - Test date range filtering.

- [ ] **Step 2: Write failing analytics API tests**
  - Test analytics endpoint returns all dashboard sections.
  - Test date filters work.
  - Test empty data returns zeros and empty lists, not errors.

- [ ] **Step 3: Implement analytics queries**
  - Use invoice item snapshots for historical accuracy.
  - Use customer transaction sums for khata balance.
  - Use buyer transaction sums for payable balance.
  - Keep queries readable and testable.

- [ ] **Step 4: Verify and commit**
  - Run analytics tests.
  - Run full backend tests.
  - Commit with `feat: add backend wholesaler analytics`.

---

## Task 15: Mobile Analytics

**Files:**
- Create: `mobile/lib/models/analytics.dart`
- Create: `mobile/lib/services/analytics_service.dart`
- Create: `mobile/lib/local/local_analytics_service.dart`
- Create: `mobile/lib/screens/analytics_screen.dart`
- Modify: `mobile/lib/app/app_dependencies.dart`
- Modify: `mobile/lib/main.dart`
- Modify: `mobile/lib/widgets/app_navigation_drawer.dart`
- Test: `mobile/test/local/local_analytics_service_test.dart`
- Test: `mobile/test/widgets/analytics_screen_test.dart`

- [ ] **Step 1: Write failing local analytics tests**
  - Seed products, buyers, customers, invoices, invoice items, buyer transactions, and customer transactions.
  - Verify revenue by company.
  - Verify profit by company.
  - Verify customer balances.
  - Verify buyer payables.
  - Verify top products.
  - Verify low stock.
  - Verify date filters.

- [ ] **Step 2: Write failing analytics screen tests**
  - Test drawer shows Analytics.
  - Test dashboard loads summary cards.
  - Test date range controls.
  - Test empty state.
  - Test error state.

- [ ] **Step 3: Implement local analytics service**
  - Use local Drift queries and computed rows.
  - Use invoice item snapshots for profit.
  - Keep calculations consistent with backend analytics tests.

- [ ] **Step 4: Implement analytics UI**
  - Keep first version simple: summary cards and short ranked lists.
  - Avoid charts until numeric summaries are correct.
  - Add date filter controls.

- [ ] **Step 5: Verify and commit**
  - Run analytics service and widget tests.
  - Run full mobile tests.
  - Commit with `feat: add wholesaler analytics dashboard`.

---

## Task 16: Backup, Import, And Migration Compatibility V2

**Files:**
- Modify: `mobile/lib/backup/backup_models.dart`
- Modify: `mobile/lib/backup/local_backup_service.dart`
- Modify: `mobile/test/backup/local_backup_service_test.dart`
- Modify: `README.md`
- Modify: `mobile/agent.md`
- Modify: `backend/agent.md`

- [ ] **Step 1: Write failing backup V2 tests**
  - Test backup includes buyers and buyer transactions.
  - Test backup includes customers and customer transactions.
  - Test backup includes product V2 fields.
  - Test backup includes invoice item snapshots needed for analytics.
  - Test restore preserves IDs and decimal strings exactly.
  - Test restore rejects missing V2 tables.

- [ ] **Step 2: Update backup schema version**
  - Increment backup schema version.
  - Update backend compatibility version.
  - Update table and column allowlists.

- [ ] **Step 3: Validate local-to-server migration readiness**
  - Document table mapping from Drift to Postgres.
  - Confirm every local table has a server equivalent or is intentionally local-only.
  - Confirm local-only tables remain excluded from server migration.

- [ ] **Step 4: Verify and commit**
  - Run backup tests.
  - Run full mobile tests.
  - Commit with `feat: update backup compatibility for wholesaler schema`.

---

## Task 17: End-To-End Wholesaler Flow QA

**Files:**
- Test: `mobile/test/app/wholesaler_flow_test.dart`
- Test: `backend/tests/api/test_wholesaler_end_to_end.py`
- Modify docs as needed after actual behavior is verified.

- [ ] **Step 1: Write mobile end-to-end test**
  - Start local mode with empty database.
  - Create first local user.
  - Add buyer.
  - Add product linked to buyer/company.
  - Add customer.
  - Create invoice with edited price and partial paid amount.
  - Verify inventory stock changes.
  - Verify customer khata ledger has invoice debit and partial collection.
  - Verify analytics revenue/profit reflect invoice.

- [ ] **Step 2: Write backend end-to-end API test**
  - Create buyer.
  - Create product.
  - Create customer.
  - Create invoice.
  - Record collection.
  - Query analytics.
  - Verify balances and profit.

- [ ] **Step 3: Run local mode APK smoke test**
  - Build release APK with `DATA_MODE=local`.
  - Install on emulator and physical Android phone if available.
  - Test setup, inventory CRUD, buyer ledger, customer khata, invoice, analytics.

- [ ] **Step 4: Run API mode smoke test**
  - Run backend.
  - Run mobile with default/API mode.
  - Verify login, inventory CRUD, buyer ledger, customer khata, invoice, analytics.

- [ ] **Step 5: Commit**
  - Commit with `test: add wholesaler end to end coverage`.

---

## Task 18: Documentation And Release APK Handoff

**Files:**
- Modify: `README.md`
- Modify: `mobile/agent.md`
- Modify: `backend/agent.md`
- Optional create: `docs/android-wholesaler-qa.md`

- [ ] **Step 1: Update documentation**
  - Document local mode APK build command.
  - Document API mode run command.
  - Document buyer/customer/product/invoice terminology.
  - Document local/server schema alignment expectations.
  - Document backup/migration compatibility.
  - Document current Drive/background scheduling limitations.

- [ ] **Step 2: Build final local-mode APK**
  - Run `(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)`.
  - Record generated APK path.
  - Verify install on emulator or phone.

- [ ] **Step 3: Run final verification**
  - Run `(cd mobile && flutter test test -r expanded)`.
  - Run backend tests.
  - Run any build or lint commands required by the repo.

- [ ] **Step 4: Commit docs**
  - Commit with `docs: document wholesaler workflow release testing`.

---

## Cross-Cutting Testing Rules

- Every behavior change starts with a failing test.
- Local and API mode tests must both pass after every task that touches shared models or services.
- Backend and local decimal calculations must be tested with non-round values.
- Ledger tests must assert both individual transaction rows and computed balances.
- Invoice tests must assert stock movement, customer ledger side effects, invoice items, and snapshots.
- Analytics tests must use invoice item snapshots, not current product values.
- UI tests must include mobile-sized layouts to catch overflow.

---

## Commit Strategy

- Commit after every task.
- Do not mix backend, mobile UI, schema, and docs in one commit unless the task explicitly requires it.
- Use messages such as:
  - `fix: stabilize local mode sign in and product creation`
  - `feat: add backend product schema v2`
  - `feat: add mobile product schema v2`
  - `feat: add buyer ledger to mobile`
  - `feat: redesign invoice creation workflow`
  - `feat: add wholesaler analytics dashboard`
  - `docs: document wholesaler workflow release testing`

---

## Risks And Mitigations

- **Risk:** Renaming Seller to Customer touches many files.
  - **Mitigation:** Rename UI labels first, then models/services in a dedicated task.
- **Risk:** Local and backend schema drift apart.
  - **Mitigation:** Use the canonical schema contract from Task 3 and add matching local/backend tests.
- **Risk:** Invoice math becomes hard to trust.
  - **Mitigation:** Test inclusive GST, price overrides, payment state side effects, cancellation, and decimal edge cases.
- **Risk:** Analytics becomes inaccurate if it reads current product costs.
  - **Mitigation:** Store buying/selling/GST snapshots on invoice items and test historical changes.
- **Risk:** Buyer ledger and inventory stock can be confused.
  - **Mitigation:** Keep Buyer ledger money-only in this version and document that inventory stock is changed through inventory/stock adjustment.
- **Risk:** Release APK differs from debug behavior.
  - **Mitigation:** Include release APK build/install smoke tests in Task 2 and Task 18.

---

## Self-Review Notes

- Spec coverage: product CRUD, buyer ledger, customer khata, invoice V2, analytics, APK testing, local/server schema alignment, and future hybrid compatibility are covered.
- Placeholder scan: no task uses TBD/TODO placeholders.
- Type consistency: canonical names are Buyer/Supplier, Customer/Khata, Product/Inventory, Invoice, CustomerTransaction, BuyerTransaction.
- Scope check: this is intentionally a multi-phase plan. Each task produces a testable increment and a commit.
