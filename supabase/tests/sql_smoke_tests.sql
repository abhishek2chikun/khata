-- SQL smoke tests for hybrid authority layer
-- Run after migrations on a fresh database.

BEGIN;

-- Schema objects exist
DO $$
BEGIN
  ASSERT (SELECT to_regclass('public.invoices') IS NOT NULL), 'invoices missing';
  ASSERT (SELECT to_regclass('public.products') IS NOT NULL), 'products missing';
  ASSERT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'create_invoice'
  ), 'create_invoice rpc missing';
END $$;

-- RLS enabled on invoices
DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class WHERE relname = 'invoices'), 'RLS not enabled on invoices';
END $$;

-- Invoice sequence works
DO $$
DECLARE
  v_num BIGINT;
BEGIN
  -- Cannot insert without auth context in plain psql; test sequence directly
  v_num := nextval('invoice_number_seq');
  ASSERT v_num >= 1, 'invoice sequence failed';
END $$;

ROLLBACK;
