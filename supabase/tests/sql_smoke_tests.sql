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

-- Core RPC behavior: auth context, master writes, invoice idempotency, cancel,
-- stock reversal, collection, and buyer/customer ledger writes.
DO $$
DECLARE
  v_user UUID := gen_random_uuid();
  v_buyer_id UUID := gen_random_uuid();
  v_customer_id UUID := gen_random_uuid();
  v_product_id UUID := gen_random_uuid();
  v_invoice_request UUID := gen_random_uuid();
  v_cancel_request UUID := gen_random_uuid();
  v_invoice_hash TEXT := 'invoice-hash-1';
  v_result JSONB;
  v_repeat JSONB;
  v_invoice_id UUID;
  v_invoice_number BIGINT;
  v_second_invoice_number BIGINT;
  v_product_qty NUMERIC;
  v_conflict_seen BOOLEAN := FALSE;
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  ) VALUES (
    v_user, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'hybrid-sql-test-' || v_user::TEXT || '@example.invalid',
    'not-used', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW()
  );
  PERFORM set_config('request.jwt.claim.sub', v_user::TEXT, TRUE);
  PERFORM set_config('role', 'authenticated', TRUE);

  v_result := public.create_buyer(
    gen_random_uuid(),
    'buyer-hash',
    jsonb_build_object(
      'id', v_buyer_id,
      'name', 'SQL Test Buyer ' || v_buyer_id::TEXT,
      'address', 'Buyer Road'
    )
  );
  ASSERT (v_result->>'id')::UUID = v_buyer_id, 'create_buyer returned wrong id';

  v_result := public.create_customer(
    gen_random_uuid(),
    'customer-hash',
    jsonb_build_object(
      'id', v_customer_id,
      'name', 'SQL Test Customer ' || v_customer_id::TEXT,
      'address', 'Customer Road'
    )
  );
  ASSERT (v_result->>'id')::UUID = v_customer_id, 'create_customer returned wrong id';

  v_result := public.upsert_company_profile(
    gen_random_uuid(),
    'company-hash',
    jsonb_build_object(
      'name', 'SQL Test Company',
      'address', 'Company Road',
      'city', 'Pune',
      'state', 'Maharashtra',
      'state_code', '27',
      'gst_flag', false
    )
  );
  ASSERT v_result->>'name' = 'SQL Test Company', 'company profile not upserted';

  v_result := public.create_product(
    gen_random_uuid(),
    'product-hash',
    jsonb_build_object(
      'id', v_product_id,
      'item_number', 'SQL-' || substring(v_product_id::TEXT from 1 for 8),
      'item_name', 'SQL Test Product',
      'category', 'General',
      'company_name', 'SQL Test Company',
      'buyer_id', v_buyer_id,
      'buying_price', 10,
      'selling_price', 12,
      'gst_rate', 0,
      'quantity_on_hand', 10,
      'low_stock_threshold', 1
    )
  );
  ASSERT (v_result->>'id')::UUID = v_product_id, 'create_product returned wrong id';

  v_result := public.create_invoice(
    v_invoice_request,
    v_invoice_hash,
    jsonb_build_object(
      'customer_id', v_customer_id,
      'place_of_supply_state', 'Maharashtra',
      'place_of_supply_state_code', '27',
      'gst_flag', false,
      'invoice_date', '2026-06-18',
      'invoice_datetime', '2026-06-18T10:00:00Z',
      'tax_regime', 'INTRA_STATE',
      'payment_state', 'CREDIT',
      'paid_amount', 0,
      'subtotal', 12,
      'discount_total', 0,
      'taxable_total', 12,
      'gst_total', 0,
      'grand_total', 12,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', v_product_id,
        'quantity', 2,
        'pricing_mode', 'PRE_TAX',
        'entered_unit_price', 12,
        'unit_price_excl_tax', 12,
        'unit_price_incl_tax', 12,
        'gst_rate', 0,
        'cgst_rate', 0,
        'sgst_rate', 0,
        'igst_rate', 0,
        'discount_percent', 0,
        'discount_amount', 0,
        'taxable_amount', 12,
        'gst_amount', 0,
        'cgst_amount', 0,
        'sgst_amount', 0,
        'igst_amount', 0,
        'line_total', 12,
        'revenue_amount', 12,
        'buying_amount', 20,
        'profit_amount', -8
      ))
    )
  );
  v_invoice_id := (v_result->'invoice'->>'id')::UUID;
  v_invoice_number := (v_result->'invoice'->>'invoice_number')::BIGINT;
  ASSERT jsonb_array_length(v_result->'items') = 1, 'invoice item not returned';
  ASSERT jsonb_array_length(v_result->'stock_movements') = 1, 'stock movement not returned';
  ASSERT jsonb_array_length(v_result->'customer_transactions') = 1, 'ledger row not returned';
  ASSERT jsonb_array_length(v_result->'products') = 1, 'updated product row not returned';

  SELECT quantity_on_hand INTO v_product_qty FROM products WHERE id = v_product_id;
  ASSERT v_product_qty = 8, 'invoice did not reduce stock';

  v_repeat := public.create_invoice(v_invoice_request, v_invoice_hash, v_result->'invoice' || jsonb_build_object('items', '[]'::JSONB));
  ASSERT (v_repeat->'invoice'->>'id')::UUID = v_invoice_id, 'invoice idempotency did not return original invoice';
  ASSERT jsonb_array_length(v_repeat->'products') = 1, 'invoice idempotency did not return product row';

  BEGIN
    PERFORM public.create_invoice(v_invoice_request, 'different-hash', v_result->'invoice' || jsonb_build_object('items', '[]'::JSONB));
  EXCEPTION WHEN unique_violation THEN
    v_conflict_seen := TRUE;
  END;
  ASSERT v_conflict_seen, 'invoice idempotency conflict not raised';

  v_result := public.create_invoice(
    gen_random_uuid(),
    'invoice-hash-2',
    jsonb_build_object(
      'customer_id', v_customer_id,
      'place_of_supply_state', 'Maharashtra',
      'place_of_supply_state_code', '27',
      'gst_flag', false,
      'invoice_date', '2026-06-18',
      'invoice_datetime', '2026-06-18T11:00:00Z',
      'tax_regime', 'INTRA_STATE',
      'payment_state', 'CREDIT',
      'paid_amount', 0,
      'subtotal', 12,
      'discount_total', 0,
      'taxable_total', 12,
      'gst_total', 0,
      'grand_total', 12,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', v_product_id,
        'quantity', 1,
        'pricing_mode', 'PRE_TAX',
        'entered_unit_price', 12,
        'unit_price_excl_tax', 12,
        'unit_price_incl_tax', 12,
        'gst_rate', 0,
        'cgst_rate', 0,
        'sgst_rate', 0,
        'igst_rate', 0,
        'discount_percent', 0,
        'discount_amount', 0,
        'taxable_amount', 12,
        'gst_amount', 0,
        'cgst_amount', 0,
        'sgst_amount', 0,
        'igst_amount', 0,
        'line_total', 12,
        'revenue_amount', 12,
        'buying_amount', 10,
        'profit_amount', 2
      ))
    )
  );
  v_second_invoice_number := (v_result->'invoice'->>'invoice_number')::BIGINT;
  ASSERT v_second_invoice_number <> v_invoice_number, 'invoice numbers not unique';

  v_result := public.cancel_invoice(
    v_invoice_id,
    v_cancel_request,
    'cancel-hash',
    'SQL smoke cancel'
  );
  ASSERT v_result->'invoice'->>'status' = 'CANCELED', 'cancel did not mark invoice canceled';
  ASSERT jsonb_array_length(v_result->'stock_movements') = 1, 'cancel stock reversal missing';
  ASSERT jsonb_array_length(v_result->'customer_transactions') >= 1, 'cancel ledger reversal missing';
  ASSERT jsonb_array_length(v_result->'products') = 1, 'cancel product row missing';

  v_repeat := public.cancel_invoice(
    v_invoice_id,
    v_cancel_request,
    'cancel-hash',
    'SQL smoke cancel retry'
  );
  ASSERT v_repeat->'invoice'->>'status' = 'CANCELED', 'cancel idempotency did not return canceled invoice';
  ASSERT jsonb_array_length(v_repeat->'products') = 1, 'cancel idempotency did not return product row';

  SELECT quantity_on_hand INTO v_product_qty FROM products WHERE id = v_product_id;
  ASSERT v_product_qty = 9, 'cancel did not restore stock';

  v_result := public.record_collection(
    gen_random_uuid(),
    'collection-hash',
    jsonb_build_object(
      'customer_id', v_customer_id,
      'amount', 5,
      'occurred_on', '2026-06-18',
      'notes', 'SQL smoke collection'
    )
  );
  ASSERT v_result->>'entry_type' = 'COLLECTION', 'record_collection failed';

  v_result := public.record_customer_ledger_entry(
    gen_random_uuid(),
    'opening-hash',
    jsonb_build_object(
      'customer_id', v_customer_id,
      'entry_type', 'OPENING_BALANCE',
      'amount', 7,
      'occurred_on', '2026-06-18'
    )
  );
  ASSERT v_result->>'entry_type' = 'OPENING_BALANCE', 'customer ledger RPC failed';

  v_result := public.record_buyer_ledger_entry(
    gen_random_uuid(),
    'buyer-ledger-hash',
    jsonb_build_object(
      'buyer_id', v_buyer_id,
      'entry_type', 'PAYMENT_MADE',
      'amount', 3,
      'occurred_at', '2026-06-18T12:00:00Z'
    )
  );
  ASSERT v_result->>'entry_type' = 'PAYMENT_MADE', 'buyer ledger RPC failed';
END $$;

ROLLBACK;
