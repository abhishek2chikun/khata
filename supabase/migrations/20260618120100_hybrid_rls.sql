-- RLS: authenticated read; direct writes blocked (official writes via SECURITY DEFINER RPC)

ALTER TABLE operator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE buyers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE buyer_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog_seed_runs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS operator_profiles_select ON operator_profiles;
DROP POLICY IF EXISTS buyers_select ON buyers;
DROP POLICY IF EXISTS customers_select ON customers;
DROP POLICY IF EXISTS products_select ON products;
DROP POLICY IF EXISTS company_profiles_select ON company_profiles;
DROP POLICY IF EXISTS invoices_select ON invoices;
DROP POLICY IF EXISTS invoice_items_select ON invoice_items;
DROP POLICY IF EXISTS stock_movements_select ON stock_movements;
DROP POLICY IF EXISTS customer_transactions_select ON customer_transactions;
DROP POLICY IF EXISTS buyer_transactions_select ON buyer_transactions;
DROP POLICY IF EXISTS catalog_seed_runs_select ON catalog_seed_runs;

CREATE POLICY operator_profiles_select ON operator_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY buyers_select ON buyers FOR SELECT TO authenticated USING (true);
CREATE POLICY customers_select ON customers FOR SELECT TO authenticated USING (true);
CREATE POLICY products_select ON products FOR SELECT TO authenticated USING (true);
CREATE POLICY company_profiles_select ON company_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY invoices_select ON invoices FOR SELECT TO authenticated USING (true);
CREATE POLICY invoice_items_select ON invoice_items FOR SELECT TO authenticated USING (true);
CREATE POLICY stock_movements_select ON stock_movements FOR SELECT TO authenticated USING (true);
CREATE POLICY customer_transactions_select ON customer_transactions FOR SELECT TO authenticated USING (true);
CREATE POLICY buyer_transactions_select ON buyer_transactions FOR SELECT TO authenticated USING (true);
CREATE POLICY catalog_seed_runs_select ON catalog_seed_runs FOR SELECT TO authenticated USING (true);

-- No INSERT/UPDATE/DELETE policies for business tables => blocked for authenticated role

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'operator_profiles', 'buyers', 'customers', 'products', 'company_profiles',
    'invoices', 'invoice_items', 'stock_movements', 'customer_transactions', 'buyer_transactions'
  ]
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%s_updated_at ON %I; CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.require_authenticated()
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid UUID;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED' USING ERRCODE = '42501';
  END IF;
  RETURN uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.idempotency_conflict()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'IDEMPOTENCY_CONFLICT' USING ERRCODE = '23505';
END;
$$;

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE invoice_number_seq TO authenticated;
