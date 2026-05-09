# Canonical Wholesaler Schema Contract

## Purpose

This document defines the canonical schema names and migration decisions for the wholesaler workflow. The contract applies to FastAPI/Postgres server mode, Flutter models and services, Drift/SQLite local mode, backups, and future local-to-server import work.

The schema uses customer naming for parties who buy from us, buyer naming for companies or suppliers we purchase goods from, and append-only ledgers for receivables and payables. Balances are derived from transactions and are not stored as mutable source-of-truth totals.

## Canonical Tables

| Canonical table | Server concept | Drift/local concept | Notes |
| --- | --- | --- | --- |
| `buyers` | Postgres table | Drift table | Supplier, brand, company, or party we purchase goods from. |
| `buyer_transactions` | Postgres table | Drift table | Money-only payable ledger for buyers. Does not change stock. |
| `customers` | Postgres table | Drift table | Customer/Khata party who buys goods from us. Replaces seller terminology. |
| `customer_transactions` | Postgres table | Drift table | Customer receivable ledger. Replaces `seller_transactions`. |
| `products` | Postgres table | Drift table | Inventory catalog with buyer/company linkage and current stock quantity. |
| `stock_movements` | Postgres table | Drift table | Stock history for opening stock, manual adjustments, invoice sales, and invoice cancellation reversals. |
| `invoices` | Postgres table | Drift table | Immutable invoice header, customer snapshot, company snapshot, payment state, totals, status, and cancellation metadata. |
| `invoice_items` | Postgres table | Drift table | Immutable invoice line snapshots for rendering, tax audit, revenue, and profit analytics. |
| `company_profiles` | Postgres table | Drift table | Active business identity and invoice branding details. |
| `local_users` | Local-only table | Drift table | Local-mode authentication user table. Server equivalent remains `app_users`. |
| `local_sessions` | Local-only table | Drift table | Local-mode session table. Server equivalent remains `user_sessions`. |
| `backup_settings` | Local-only table | Drift table | Device backup configuration. Excluded from server business-data import. |
| `backup_events` | Local-only table | Drift table | Device backup/import audit history. Excluded from server business-data import. |

Server authentication keeps `app_users` and `user_sessions` as backend auth tables. Local authentication keeps `local_users` and `local_sessions` because local login has device-specific session semantics.

## Shared Storage Rules

- Primary keys are UUID strings in mobile models and Drift, and UUID columns in Postgres.
- Server timestamps use timezone-aware Postgres timestamps. API JSON and Drift store UTC ISO-8601 strings with offsets or UTC `Z` suffix.
- Server decimal values use Python `Decimal` and Postgres `NUMERIC` with explicit precision and scale.
- API JSON represents decimal fields as normalized decimal strings, not binary floating-point values.
- Drift stores decimal fields as normalized decimal strings in `TEXT` columns. UI parsing can use numeric widgets, but persisted values and service boundaries use strings or decimal value objects.
- Money fields use scale 2. Quantity fields use scale 3. GST percentage fields use scale 2.
- Stored ledger amounts are positive magnitudes. The entry type defines whether a row increases or decreases the derived balance.
- Derived balances are computed with transaction sums each time they are read or materialized for display. Customer and buyer master rows do not store authoritative balance totals.

## Products

### Canonical Fields

| Field | Server representation | Drift representation | Required | Notes |
| --- | --- | --- | --- | --- |
| `id` | `UUID` | `TEXT` UUID | Yes | Stable product identifier. |
| `item_number` | `TEXT` or bounded string, unique | `TEXT`, unique | Yes | Replaces current `item_code`. Human/business-visible product number. |
| `item_name` | `TEXT` | `TEXT` | Yes | Product display name. |
| `category` | `TEXT` | `TEXT` | Yes | Product category used for filtering and uniqueness. |
| `buyer_id` | `UUID NULL REFERENCES buyers(id)` | `TEXT NULL REFERENCES buyers(id)` | No | Nullable during migration and for products created before buyer records exist. |
| `company_name` | `TEXT` | `TEXT` | Yes | Replaces current `company`. Mirrors `buyers.name` when `buyer_id` is set. |
| `buying_price` | `NUMERIC(14,2)` | Decimal string | Yes | Price paid to buyer/supplier, inclusive of GST. Legacy pre-tax buying prices are converted during migration. |
| `selling_price` | `NUMERIC(14,2)` | Decimal string | Yes | Default customer invoice price per unit, inclusive of GST. |
| `unit` | `TEXT NULL` | `TEXT NULL` | No | Unit label such as `pcs`, `box`, or `kg`. |
| `gst_rate` | `NUMERIC(5,2)` | Decimal string | Yes | Default GST percentage for invoice lines. |
| `quantity_on_hand` | `NUMERIC(14,3)` | Decimal string | Yes | Current stock quantity. Updated through stock movements and invoice side effects. |
| `low_stock_threshold` | `NUMERIC(14,3)` | Decimal string | Yes | Low-stock alert threshold. Default is `0.000`. |
| `is_active` | `BOOLEAN` | `BOOLEAN` | Yes | Archive flag. Inactive products remain referenced by invoices. |
| `created_at` | `TIMESTAMPTZ` | UTC ISO-8601 text | Yes | Creation timestamp. |
| `updated_at` | `TIMESTAMPTZ` | UTC ISO-8601 text | Yes | Last master-data update timestamp. |

### Product Constraints

- `item_number` is globally unique across active and archived rows.
- `(company_name, item_name, category)` is globally unique across active and archived rows. Reactivation or renaming is the supported path when an archived product identity needs to be reused.
- `buyer_id` and `company_name` must agree when `buyer_id` is present: `company_name` is copied from the linked buyer name at product save time.
- Product edit does not directly rewrite `quantity_on_hand`. Stock changes use `stock_movements`, invoice creation, or invoice cancellation.

## Buyers

`buyers` represent the company, brand, supplier, or party we buy stock from.

Canonical fields:

| Field | Representation | Notes |
| --- | --- | --- |
| `id` | UUID / UUID text | Stable buyer identifier. |
| `name` | Text | Unique buyer/company name used by products as `company_name`. |
| `address` | Text, default empty | Postal address. |
| `state` | Nullable text | Buyer state name. |
| `state_code` | Nullable text | Buyer state code. |
| `phone` | Nullable text | Contact phone. |
| `gstin` | Nullable text | GST registration number. |
| `is_active` | Boolean | Archive flag. |
| `created_at`, `updated_at` | Timestamp | Audit timestamps. |

Buyer duplicate behavior is deterministic: duplicate `name` is rejected. Duplicate `phone` with a different name is allowed unless a future validated business rule requires phone uniqueness.

## Buyer Ledger

`buyer_transactions` is an append-only payable ledger. It records money owed to or paid to buyers. It does not update product stock and does not create product rows.

Canonical fields:

| Field | Representation | Notes |
| --- | --- | --- |
| `id` | UUID / UUID text | Stable transaction identifier. |
| `buyer_id` | UUID / UUID text reference | Required reference to `buyers`. |
| `request_id` | Nullable UUID / UUID text | Required for standalone API/local user-created writes. Null for system rows if a parent write owns idempotency. |
| `request_hash` | Nullable text | Normalized payload hash paired with `request_id`. |
| `entry_type` | Enum text | Determines balance direction. |
| `amount` | `NUMERIC(14,2)` / decimal string | Positive money amount. |
| `occurred_at` | Timestamp | Business date and time visible and editable in the UI. |
| `notes` | Nullable text | User note. |
| `created_by_user_id` | Auth user reference | Server uses `app_users.id`; local uses `local_users.id`. |
| `created_at` | Timestamp | Write timestamp. |

Entry types and balance effects:

| Entry type | Effect on payable balance | Use |
| --- | --- | --- |
| `OPENING_PAYABLE` | Increases payable | Initial amount already owed to buyer. One row per buyer. |
| `PURCHASE_AMOUNT` | Increases payable | Manual purchase/accounting amount for buyer ledger. Stock is handled separately. |
| `PAYMENT_MADE` | Decreases payable | Money paid to buyer. |
| `PAYABLE_INCREASE_ADJUSTMENT` | Increases payable | Audited correction that raises payable. |
| `PAYABLE_DECREASE_ADJUSTMENT` | Decreases payable | Audited correction that lowers payable. |

Payable balance formula:

`sum(OPENING_PAYABLE + PURCHASE_AMOUNT + PAYABLE_INCREASE_ADJUSTMENT) - sum(PAYMENT_MADE + PAYABLE_DECREASE_ADJUSTMENT)`.

## Customers

`customers` are the parties who buy goods from us and have khata/receivable history. This name replaces current seller terminology.

Canonical fields:

| Field | Representation | Notes |
| --- | --- | --- |
| `id` | UUID / UUID text | Stable customer identifier. |
| `name` | Text | Customer display name. |
| `address` | Text, default empty | Postal address. |
| `state` | Nullable text | Customer state name. |
| `state_code` | Nullable text | Customer state code used for invoice place of supply defaults. |
| `phone` | Nullable text | Contact phone. |
| `gstin` | Nullable text | GST registration number. |
| `is_active` | Boolean | Archive flag. |
| `created_at`, `updated_at` | Timestamp | Audit timestamps. |

The existing uniqueness behavior `(name, phone)` remains the canonical starting constraint for migrated customer rows.

## Customer Ledger

`customer_transactions` is an append-only receivable ledger. Every invoice creates a full invoice debit, and payment-state-specific collection rows are added against the same invoice when applicable.

Canonical fields:

| Field | Representation | Notes |
| --- | --- | --- |
| `id` | UUID / UUID text | Stable transaction identifier. |
| `customer_id` | UUID / UUID text reference | Required reference to `customers`. |
| `invoice_id` | Nullable UUID / UUID text reference | Required for invoice-created debit, collection, and cancellation rows. Null for manual opening balance and adjustments. |
| `request_id` | Nullable UUID / UUID text | Required for standalone API/local user-created writes. Null for rows created inside invoice create or cancel because the invoice write owns idempotency. |
| `request_hash` | Nullable text | Normalized payload hash paired with `request_id`. |
| `opening_balance_customer_id` | Nullable UUID / UUID text | Partial-unique key helper for one opening balance per customer where needed in Drift. |
| `entry_type` | Enum text | Determines balance direction. |
| `amount` | `NUMERIC(14,2)` / decimal string | Positive money amount. |
| `occurred_at` | Timestamp | Business date and time visible and editable in the UI. |
| `notes` | Nullable text | User note. |
| `created_by_user_id` | Auth user reference | Server uses `app_users.id`; local uses `local_users.id`. |
| `created_at` | Timestamp | Write timestamp. |

Entry types and balance effects:

| Entry type | Effect on receivable balance | Use |
| --- | --- | --- |
| `OPENING_BALANCE` | Increases receivable | Initial amount customer already owes. One row per customer. |
| `INVOICE_DEBIT` | Increases receivable | Full invoice amount for every created invoice, including paid and partially paid invoices. |
| `COLLECTION_RECEIVED` | Decreases receivable | Money received from customer, including immediate invoice collection rows. |
| `INVOICE_CANCEL_REVERSAL` | Decreases receivable | Reverses the original invoice debit on cancellation. |
| `COLLECTION_CANCEL_REVERSAL` | Increases receivable | Reverses any invoice-linked collection row when a paid or partially paid invoice is canceled. |
| `BALANCE_INCREASE_ADJUSTMENT` | Increases receivable | Audited correction that raises customer balance. |
| `BALANCE_DECREASE_ADJUSTMENT` | Decreases receivable | Audited correction that lowers customer balance. |

Receivable balance formula:

`sum(OPENING_BALANCE + INVOICE_DEBIT + COLLECTION_CANCEL_REVERSAL + BALANCE_INCREASE_ADJUSTMENT) - sum(COLLECTION_RECEIVED + INVOICE_CANCEL_REVERSAL + BALANCE_DECREASE_ADJUSTMENT)`.

### Customer Ledger Timestamps

- Invoice-created `INVOICE_DEBIT` rows use the parent invoice `invoice_datetime` as `occurred_at`.
- Immediate `COLLECTION_RECEIVED` rows created for `TOTAL_PAID` or `PARTIAL_PAID` invoices use the same `invoice_datetime` as `occurred_at` unless the UI explicitly captures a different collection datetime at invoice creation.
- `INVOICE_CANCEL_REVERSAL` and `COLLECTION_CANCEL_REVERSAL` rows use the invoice `canceled_at` timestamp as `occurred_at`.
- Manual `COLLECTION_RECEIVED`, `OPENING_BALANCE`, `BALANCE_INCREASE_ADJUSTMENT`, and `BALANCE_DECREASE_ADJUSTMENT` rows use the user-entered datetime as `occurred_at`; the UI default is the current device/server time at form open.

## Invoices

### Payment States

`invoices.payment_state` replaces the older two-state paid/credit mode.

| Payment state | Required paid amount | Customer ledger side effects |
| --- | --- | --- |
| `CREDIT` | `0.00` | Create one `INVOICE_DEBIT` for the full invoice total. |
| `TOTAL_PAID` | Equal to `grand_total` | Create one `INVOICE_DEBIT` for the full invoice total and one `COLLECTION_RECEIVED` for the full invoice total. |
| `PARTIAL_PAID` | Greater than `0.00` and less than `grand_total` | Create one `INVOICE_DEBIT` for the full invoice total and one `COLLECTION_RECEIVED` for the paid amount. |

Invoices store `paid_amount` as a decimal. For `CREDIT`, it is `0.00`. For `TOTAL_PAID`, it equals `grand_total`. For `PARTIAL_PAID`, it is the exact collected amount at invoice creation.

### Cancellation Ledger Side Effects

Cancellation writes positive-magnitude ledger rows whose direction is determined by `entry_type`.

| Original payment state | Cancellation rows | Net customer-balance effect |
| --- | --- | --- |
| `CREDIT` | One `INVOICE_CANCEL_REVERSAL` with `amount = grand_total`, `invoice_id` set, and `occurred_at = canceled_at`. | Decreases receivable by `grand_total`, exactly reversing the original `INVOICE_DEBIT`. |
| `TOTAL_PAID` | One `INVOICE_CANCEL_REVERSAL` with `amount = grand_total` and one `COLLECTION_CANCEL_REVERSAL` with `amount = grand_total`; both rows set `invoice_id` and `occurred_at = canceled_at`. | The reversal debit decreases receivable by `grand_total`; the collection reversal increases receivable by `grand_total`; net balance change is `0.00`, restoring the customer's pre-invoice balance while preserving audit rows. |
| `PARTIAL_PAID` | One `INVOICE_CANCEL_REVERSAL` with `amount = grand_total` and one `COLLECTION_CANCEL_REVERSAL` with `amount = paid_amount`; both rows set `invoice_id` and `occurred_at = canceled_at`. | The reversal debit decreases receivable by `grand_total`; the collection reversal increases receivable by `paid_amount`; net balance change is `paid_amount - grand_total`, exactly reversing the invoice's original net receivable increase. |

Cancellation rows are inserted in the same transaction as invoice status changes and stock restoration. Repeated cancellation requests with the same cancel request identity return the existing canceled invoice and do not add duplicate ledger rows.

### Header Fields

Canonical invoice header fields include:

- `id`, `request_id`, `request_hash`, `invoice_number`, `customer_id`, `invoice_datetime`, `status`, `payment_state`, `paid_amount`, `tax_regime`, `subtotal`, `taxable_total`, `gst_total`, `grand_total`, `notes`, cancellation metadata, `created_by_user_id`, and `created_at`.
- Customer snapshot: `customer_name`, `customer_address`, `customer_state`, `customer_state_code`, `customer_phone`, `customer_gstin`, `place_of_supply_state`, and `place_of_supply_state_code`.
- Company profile snapshot: `company_name`, `company_address`, `company_city`, `company_state`, `company_state_code`, `company_gstin`, `company_phone`, `company_email`, `company_bank_name`, `company_bank_account`, `company_bank_ifsc`, `company_bank_branch`, and `company_jurisdiction`.

### Invoice Item Snapshot Fields

Each `invoice_items` row stores immutable product and pricing snapshots:

- Identity and ordering: `id`, `invoice_id`, `product_id`, `line_number`.
- Product snapshot: `item_number`, `item_name`, `category`, `buyer_id`, `company_name`, and `unit`.
- Cost and selling snapshots: `buying_price`, `selling_price`, `entered_unit_price`, `unit_price_excl_tax`, `unit_price_incl_tax`.
- Quantity and GST: `quantity`, `gst_rate`, `cgst_rate`, `sgst_rate`, `igst_rate`.
- Totals: `taxable_amount`, `gst_amount`, `cgst_amount`, `sgst_amount`, `igst_amount`, and `line_total`.

Buying price is stored on invoice items for historical profit analytics. Invoice rendering must not expose buying price to customers.

## Inclusive GST Math

Invoice line prices default to GST-inclusive pricing. The persisted invoice item stores both the entered inclusive price and normalized tax values.

For a line with quantity `q`, GST-inclusive unit selling price `p`, and GST rate percentage `r`:

- `unit_price_incl_tax = p`
- `unit_price_excl_tax = round_money(p / (1 + (r / 100)))`
- `unit_gst_amount = p - unit_price_excl_tax`
- `taxable_amount = round_money(unit_price_excl_tax * q)`
- `line_total = round_money(p * q)`
- `gst_amount = line_total - taxable_amount`
- For intra-state invoices, `cgst_rate = r / 2`, `sgst_rate = r / 2`, `igst_rate = 0.00`, and `cgst_amount + sgst_amount = gst_amount`.
- For inter-state invoices, `igst_rate = r`, `cgst_rate = 0.00`, `sgst_rate = 0.00`, and `igst_amount = gst_amount`.

Rounding policy is line-level `ROUND_HALF_UP` to 2 decimal places for money. Quantities are rounded or normalized to 3 decimal places. Invoice totals are sums of stored line values and are not recomputed from current product values.

## Stock Movements

`stock_movements` remains the stock history table. Canonical fields are `id`, `product_id`, nullable `invoice_id`, nullable `request_id`, nullable `request_hash`, `movement_type`, `quantity_delta`, nullable `reason`, `created_by_user_id`, and `created_at`.

Movement types:

| Movement type | Quantity effect | Use |
| --- | --- | --- |
| `OPENING` | Positive | Initial stock for a new or migrated product. |
| `MANUAL_ADJUSTMENT` | Positive or negative | User-entered correction. |
| `INVOICE_SALE` | Negative | Stock reduction during invoice creation. |
| `INVOICE_CANCEL_REVERSAL` | Positive | Stock restoration during invoice cancellation. |

`quantity_on_hand` can be stored on `products` as the current stock value for efficient display, but stock history and auditability come from `stock_movements`.

## Migration Naming Decisions

- Current `sellers` becomes canonical `customers`.
- Current `seller_transactions` becomes canonical `customer_transactions`.
- Current product `item_code` becomes canonical `item_number`.
- Current product `company` becomes canonical `company_name`.
- `company_name` links to `buyers.name`. When a product has `buyer_id`, product `company_name` is the buyer name snapshot used for filtering, invoice snapshots, and analytics grouping.
- Existing invoice `seller_*` snapshot fields become `customer_*` snapshot fields.
- Existing invoice item `product_code` becomes `item_number` and existing invoice item `company` becomes `company_name`.

Migration scripts must preserve IDs, ledger rows, invoice rows, invoice item order, timestamps, request IDs, request hashes, and cancellation metadata.

### Product Field Migration

| Current field | Canonical field | Migration rule |
| --- | --- | --- |
| `company` | `company_name`, `buyer_id` | Copy `company` into `company_name`. Match an existing buyer by exact `buyers.name = company_name`; create one active buyer with that name when none exists; store the matched or created buyer ID in `buyer_id`. |
| `item_code` | `item_number` | Copy the normalized legacy value directly and enforce global uniqueness across active and archived products. |
| `item_name` | `item_name` | Copy directly. |
| `category` | `category` | Copy directly. |
| `buying_price_excl_tax` | `buying_price` | Treat the legacy value as pre-tax data. Convert to inclusive price using `buying_gst_rate` when present: `round_money(buying_price_excl_tax * (1 + buying_gst_rate / 100))`. When `buying_gst_rate` is null, copy the legacy value into `buying_price` and record the migrated row as having unknown buying GST in the migration report. |
| `default_selling_price_excl_tax` | `selling_price` | Treat the legacy value as pre-tax data and convert to the new inclusive default: `round_money(default_selling_price_excl_tax * (1 + default_gst_rate / 100))`. The canonical product row does not keep pricing-mode metadata; invoice item snapshots created before migration retain their original normalized tax fields. |
| `default_gst_rate` | `gst_rate` | Copy directly as the default invoice-line GST rate. |
| `quantity_on_hand` | `quantity_on_hand` | Copy directly with 3-decimal normalization. |
| `low_stock_threshold` | `low_stock_threshold` | Copy directly with 3-decimal normalization. |
| `is_active` | `is_active` | Copy directly. |

### Seller Transaction Entry-Type Migration

| Current `seller_transactions.entry_type` | Canonical `customer_transactions.entry_type` | Migration rule |
| --- | --- | --- |
| `CREDIT_SALE` | `INVOICE_DEBIT` | Copy amount as a positive magnitude, keep `invoice_id`, and use the migrated invoice `invoice_datetime` as `occurred_at` when the invoice exists; otherwise preserve the old transaction business date/time. |
| `PAYMENT` | `COLLECTION_RECEIVED` | Copy amount as a positive magnitude. Use the old transaction business date/time as `occurred_at`. |
| `OPENING_BALANCE` | `OPENING_BALANCE` | Same meaning under the customer ledger; copy amount as a positive magnitude and preserve one-opening-balance-per-customer behavior. |
| `BALANCE_INCREASE_ADJUSTMENT` | `BALANCE_INCREASE_ADJUSTMENT` | Same meaning under the customer ledger; copy amount as a positive magnitude. |
| `BALANCE_DECREASE_ADJUSTMENT` | `BALANCE_DECREASE_ADJUSTMENT` | Same meaning under the customer ledger; copy amount as a positive magnitude. |
| `INVOICE_CANCEL_REVERSAL` | `INVOICE_CANCEL_REVERSAL` and, where required, `COLLECTION_CANCEL_REVERSAL` | For legacy credit invoices, copy as `INVOICE_CANCEL_REVERSAL`. For migrated `TOTAL_PAID` and `PARTIAL_PAID` invoices, create cancellation rows according to the cancellation side-effect table so the invoice debit and any immediate collection are both reversed with auditable rows. |

Old `seller_id` references become `customer_id`. Old `occurred_on` date values are converted to `occurred_at` using the start of that local business day when no more precise timestamp exists.

## Compatibility Policy

- Backend exposes new `/customers` routes and customer-named schemas, services, models, and tests.
- Mobile uses customer naming everywhere in UI text, models, services, local services, and tests.
- Existing `/sellers` routes may remain as temporary aliases only when needed to keep current backend tests or deployed migration clients working during the transition. Alias routes must call customer services and must not introduce independent seller business logic.
- Local Drift schema bumps to `schemaVersion = 2` when canonical product/customer/buyer/invoice tables are implemented.
- Drift version 2 migration renames or rebuilds local tables to canonical names and migrates existing test-device local databases from seller/product V1 names.
- Backup payload version increments when V2 tables are introduced. Backup restore must preserve decimal strings exactly.
- Production code is not changed by this documentation task. Table, API, and Drift changes occur in subsequent implementation tasks with tests.

## Local And Server Table Alignment Review

| Local table | Backend/Postgres concept | Classification |
| --- | --- | --- |
| `buyers` | `buyers` | Shared business table. |
| `buyer_transactions` | `buyer_transactions` | Shared business table. |
| `customers` | `customers` | Shared business table. |
| `customer_transactions` | `customer_transactions` | Shared business table. |
| `products` | `products` | Shared business table. |
| `stock_movements` | `stock_movements` | Shared business table. |
| `invoices` | `invoices` | Shared business table. |
| `invoice_items` | `invoice_items` | Shared business table. |
| `company_profiles` | `company_profiles` | Shared business table. |
| `local_users` | `app_users` | Local-only auth table with server auth equivalent. |
| `local_sessions` | `user_sessions` | Local-only auth table with server auth equivalent. |
| `backup_settings` | None | Local-only device configuration. |
| `backup_events` | None | Local-only backup/import audit table. |

## Decimal Field Review

| Field group | Fields | Server representation | Local representation |
| --- | --- | --- | --- |
| Product money | `buying_price`, `selling_price` | `NUMERIC(14,2)` and Python `Decimal` | Normalized decimal string with 2 fractional digits. |
| Product quantity | `quantity_on_hand`, `low_stock_threshold` | `NUMERIC(14,3)` and Python `Decimal` | Normalized decimal string with 3 fractional digits. |
| Product GST | `gst_rate` | `NUMERIC(5,2)` and Python `Decimal` | Normalized decimal string with 2 fractional digits. |
| Ledger money | `buyer_transactions.amount`, `customer_transactions.amount` | `NUMERIC(14,2)` and Python `Decimal` | Normalized decimal string with 2 fractional digits. |
| Invoice totals | `subtotal`, `taxable_total`, `gst_total`, `grand_total`, `paid_amount` | `NUMERIC(14,2)` and Python `Decimal` | Normalized decimal string with 2 fractional digits. |
| Invoice item money | `buying_price`, `selling_price`, `entered_unit_price`, `unit_price_excl_tax`, `unit_price_incl_tax`, `taxable_amount`, `gst_amount`, tax split amounts, `line_total` | `NUMERIC(14,2)` and Python `Decimal` | Normalized decimal string with 2 fractional digits. |
| Invoice item quantity | `quantity` | `NUMERIC(14,3)` and Python `Decimal` | Normalized decimal string with 3 fractional digits. |
| Invoice item GST | `gst_rate`, `cgst_rate`, `sgst_rate`, `igst_rate` | `NUMERIC(5,2)` and Python `Decimal` | Normalized decimal string with 2 fractional digits. |
| Stock movement quantity | `quantity_delta` | `NUMERIC(14,3)` and Python `Decimal` | Normalized decimal string with 3 fractional digits. |

## Self-Review Notes

- Every mobile local table has a matching backend/Postgres concept or is explicitly classified as local-only.
- Every decimal field group has exact local and server representations.
- Buyer payable and customer receivable balances are computed from append-only transactions.
- Migration naming is explicit for seller/customer and product field changes.
- Compatibility policy separates new canonical routes from temporary seller aliases.
- The contract contains no placeholder sections or deferred naming decisions.
