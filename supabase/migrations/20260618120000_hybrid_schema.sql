-- Hybrid Khata authority schema (mirrors backend schema-10 + Supabase auth)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Invoice numbering owned by Postgres
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq AS BIGINT START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS operator_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS buyers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  address VARCHAR(500) NOT NULL,
  state VARCHAR(255),
  state_code VARCHAR(50),
  phone VARCHAR(50),
  gstin VARCHAR(50),
  whatsapp_number VARCHAR(50),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  address VARCHAR(500) NOT NULL,
  state VARCHAR(255),
  state_code VARCHAR(50),
  phone VARCHAR(50),
  gstin VARCHAR(50),
  whatsapp_number VARCHAR(50),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_customers_name_phone UNIQUE (name, phone)
);

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_number VARCHAR(255) NOT NULL UNIQUE,
  item_name VARCHAR(255) NOT NULL,
  category VARCHAR(255) NOT NULL,
  company_name VARCHAR(255) NOT NULL,
  buyer_id UUID REFERENCES buyers(id),
  buying_price NUMERIC(14, 3) NOT NULL,
  selling_price NUMERIC(14, 3) NOT NULL,
  unit VARCHAR(50),
  hsn_code VARCHAR(32),
  gst_rate NUMERIC(5, 2) NOT NULL,
  quantity_on_hand NUMERIC(14, 3) NOT NULL DEFAULT 0,
  low_stock_threshold NUMERIC(14, 3) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_products_company_name_item_name_category UNIQUE (company_name, item_name, category)
);

CREATE TABLE IF NOT EXISTS company_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  address VARCHAR(500) NOT NULL,
  city VARCHAR(255) NOT NULL,
  state VARCHAR(255) NOT NULL,
  state_code VARCHAR(50) NOT NULL,
  gstin VARCHAR(50),
  gst_flag BOOLEAN NOT NULL DEFAULT FALSE,
  phone VARCHAR(50),
  email VARCHAR(255),
  bank_name TEXT,
  bank_account VARCHAR(255),
  bank_ifsc VARCHAR(100),
  bank_branch TEXT,
  jurisdiction TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_company_profiles_single_active
  ON company_profiles (is_active) WHERE is_active = TRUE;

CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL UNIQUE,
  request_hash VARCHAR(255) NOT NULL,
  invoice_number BIGINT NOT NULL DEFAULT nextval('invoice_number_seq') UNIQUE,
  customer_id UUID NOT NULL REFERENCES customers(id),
  customer_name TEXT NOT NULL,
  customer_address TEXT NOT NULL,
  customer_state TEXT,
  customer_state_code VARCHAR(50),
  customer_phone VARCHAR(50),
  customer_whatsapp_number VARCHAR(50),
  customer_gstin VARCHAR(50),
  place_of_supply_state TEXT NOT NULL,
  place_of_supply_state_code VARCHAR(50) NOT NULL,
  company_name TEXT NOT NULL,
  company_address TEXT NOT NULL,
  company_city TEXT NOT NULL,
  company_state TEXT NOT NULL,
  company_state_code VARCHAR(50) NOT NULL,
  company_gstin VARCHAR(50),
  company_phone VARCHAR(50),
  company_email VARCHAR(255),
  company_bank_name TEXT,
  company_bank_account VARCHAR(255),
  company_bank_ifsc VARCHAR(100),
  company_bank_branch TEXT,
  company_jurisdiction TEXT,
  gst_flag BOOLEAN NOT NULL DEFAULT FALSE,
  invoice_date DATE NOT NULL,
  invoice_datetime TIMESTAMPTZ NOT NULL,
  tax_regime VARCHAR(32) NOT NULL CHECK (tax_regime IN ('INTRA_STATE', 'INTER_STATE')),
  status VARCHAR(32) NOT NULL CHECK (status IN ('ACTIVE', 'CANCELED')),
  payment_state VARCHAR(32) NOT NULL CHECK (payment_state IN ('CREDIT', 'TOTAL_PAID', 'PARTIAL_PAID')),
  paid_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  subtotal NUMERIC(14, 2) NOT NULL,
  discount_total NUMERIC(14, 2) NOT NULL,
  taxable_total NUMERIC(14, 2) NOT NULL,
  gst_total NUMERIC(14, 2) NOT NULL,
  grand_total NUMERIC(14, 2) NOT NULL,
  notes TEXT,
  created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
  cancel_request_id UUID UNIQUE,
  cancel_request_hash VARCHAR(255),
  canceled_by_user_id UUID REFERENCES auth.users(id),
  cancel_reason TEXT,
  canceled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_invoices_payment_amount_matches_state CHECK (
    (payment_state = 'CREDIT' AND paid_amount = 0)
    OR (payment_state = 'TOTAL_PAID' AND paid_amount = grand_total)
    OR (payment_state = 'PARTIAL_PAID' AND paid_amount > 0 AND paid_amount < grand_total)
  ),
  CONSTRAINT ck_invoices_cancel_fields CHECK (
    (status = 'ACTIVE' AND cancel_request_id IS NULL AND cancel_request_hash IS NULL
      AND canceled_by_user_id IS NULL AND cancel_reason IS NULL AND canceled_at IS NULL)
    OR (status = 'CANCELED' AND cancel_request_id IS NOT NULL AND cancel_request_hash IS NOT NULL
      AND canceled_by_user_id IS NOT NULL AND cancel_reason IS NOT NULL AND canceled_at IS NOT NULL)
  )
);

ALTER SEQUENCE invoice_number_seq OWNED BY invoices.invoice_number;

CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  line_number INTEGER NOT NULL,
  product_item_number VARCHAR(255) NOT NULL,
  product_item_name TEXT NOT NULL,
  product_category VARCHAR(255) NOT NULL,
  product_buyer_id UUID,
  product_company_name VARCHAR(255) NOT NULL,
  product_hsn_code VARCHAR(32),
  buying_price NUMERIC(14, 3) NOT NULL,
  selling_price NUMERIC(14, 3) NOT NULL,
  unit VARCHAR(50),
  product_name TEXT NOT NULL,
  product_code VARCHAR(255) NOT NULL,
  company VARCHAR(255) NOT NULL,
  category VARCHAR(255) NOT NULL,
  quantity NUMERIC(14, 3) NOT NULL,
  pricing_mode VARCHAR(32) NOT NULL CHECK (pricing_mode IN ('PRE_TAX', 'TAX_INCLUSIVE')),
  entered_unit_price NUMERIC(14, 3) NOT NULL,
  unit_price_excl_tax NUMERIC(14, 3) NOT NULL,
  unit_price_incl_tax NUMERIC(14, 3) NOT NULL,
  gst_rate NUMERIC(5, 2) NOT NULL,
  cgst_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
  sgst_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
  igst_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
  discount_percent NUMERIC(5, 2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(14, 2) NOT NULL,
  taxable_amount NUMERIC(14, 2) NOT NULL,
  gst_amount NUMERIC(14, 2) NOT NULL,
  cgst_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  sgst_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  igst_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  line_total NUMERIC(14, 2) NOT NULL,
  revenue_amount NUMERIC(14, 2) NOT NULL,
  buying_amount NUMERIC(14, 2) NOT NULL,
  profit_amount NUMERIC(14, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_invoice_items_invoice_id_line_number UNIQUE (invoice_id, line_number),
  CONSTRAINT ck_invoice_items_rate_sum CHECK (cgst_rate + sgst_rate + igst_rate = gst_rate),
  CONSTRAINT ck_invoice_items_amount_sum CHECK (cgst_amount + sgst_amount + igst_amount = gst_amount)
);

CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id),
  invoice_id UUID REFERENCES invoices(id),
  request_id UUID UNIQUE,
  request_hash VARCHAR(255),
  movement_type VARCHAR(50) NOT NULL,
  quantity_delta NUMERIC(14, 3) NOT NULL CHECK (quantity_delta <> 0),
  reason VARCHAR(500),
  created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_stock_movements_shape CHECK (
    (movement_type = 'OPENING' AND invoice_id IS NULL AND request_id IS NULL AND request_hash IS NOT NULL)
    OR (movement_type = 'MANUAL_ADJUSTMENT' AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL)
    OR (movement_type IN ('INVOICE_SALE', 'INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)
  )
);

CREATE TABLE IF NOT EXISTS customer_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  invoice_id UUID REFERENCES invoices(id),
  request_id UUID UNIQUE,
  request_hash VARCHAR(255),
  opening_balance_customer_id UUID,
  entry_type VARCHAR(64) NOT NULL,
  amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
  occurred_on DATE NOT NULL,
  notes VARCHAR(500),
  created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_customer_transactions_shape CHECK (
    (entry_type IN ('OPENING_BALANCE', 'COLLECTION', 'BALANCE_INCREASE_ADJUSTMENT', 'BALANCE_DECREASE_ADJUSTMENT')
      AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL)
    OR (entry_type IN ('CREDIT_SALE', 'COLLECTION', 'INVOICE_CANCEL_REVERSAL', 'COLLECTION_REVERSAL')
      AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_transactions_opening_balance
  ON customer_transactions (customer_id) WHERE entry_type = 'OPENING_BALANCE';

CREATE TABLE IF NOT EXISTS buyer_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES buyers(id),
  request_id UUID UNIQUE,
  request_hash VARCHAR(255),
  entry_type VARCHAR(64) NOT NULL,
  amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
  occurred_at TIMESTAMPTZ NOT NULL,
  notes VARCHAR(500),
  created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_buyer_transactions_entry_type CHECK (
    entry_type IN (
      'OPENING_PAYABLE', 'PURCHASE_AMOUNT', 'PAYMENT_MADE',
      'PAYABLE_INCREASE_ADJUSTMENT', 'PAYABLE_DECREASE_ADJUSTMENT'
    ) AND request_id IS NOT NULL AND request_hash IS NOT NULL
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_buyer_transactions_opening_payable
  ON buyer_transactions (buyer_id) WHERE entry_type = 'OPENING_PAYABLE';

CREATE TABLE IF NOT EXISTS catalog_seed_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  catalog_version INTEGER NOT NULL,
  product_count INTEGER NOT NULL,
  buyer_count INTEGER NOT NULL,
  seeded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  allow_stock_reset BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_products_updated_at ON products (updated_at);
CREATE INDEX IF NOT EXISTS idx_customers_updated_at ON customers (updated_at);
CREATE INDEX IF NOT EXISTS idx_buyers_updated_at ON buyers (updated_at);
CREATE INDEX IF NOT EXISTS idx_invoices_updated_at ON invoices (updated_at);
CREATE INDEX IF NOT EXISTS idx_invoice_items_updated_at ON invoice_items (updated_at);
CREATE INDEX IF NOT EXISTS idx_stock_movements_updated_at ON stock_movements (updated_at);
CREATE INDEX IF NOT EXISTS idx_customer_transactions_updated_at ON customer_transactions (updated_at);
CREATE INDEX IF NOT EXISTS idx_buyer_transactions_updated_at ON buyer_transactions (updated_at);
CREATE INDEX IF NOT EXISTS idx_company_profiles_updated_at ON company_profiles (updated_at);
