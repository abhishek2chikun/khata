-- Remaining hybrid write RPCs for buyer ledger and batch/customer ledger writes.

CREATE OR REPLACE FUNCTION public.create_buyer(
  p_request_id UUID,
  p_request_hash TEXT,
  p_buyer JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row buyers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();

  INSERT INTO buyers (
    id, name, address, state, state_code, phone, gstin, whatsapp_number,
    is_active, created_at, updated_at
  ) VALUES (
    COALESCE((p_buyer->>'id')::UUID, gen_random_uuid()),
    p_buyer->>'name',
    COALESCE(p_buyer->>'address', ''),
    p_buyer->>'state',
    p_buyer->>'state_code',
    p_buyer->>'phone',
    p_buyer->>'gstin',
    p_buyer->>'whatsapp_number',
    TRUE,
    NOW(),
    NOW()
  ) RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_buyer(
  p_request_id UUID,
  p_request_hash TEXT,
  p_buyer JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row buyers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();

  UPDATE buyers SET
    name = COALESCE(p_buyer->>'name', name),
    address = COALESCE(p_buyer->>'address', address),
    state = COALESCE(p_buyer->>'state', state),
    state_code = COALESCE(p_buyer->>'state_code', state_code),
    phone = COALESCE(p_buyer->>'phone', phone),
    gstin = COALESCE(p_buyer->>'gstin', gstin),
    whatsapp_number = COALESCE(p_buyer->>'whatsapp_number', whatsapp_number),
    updated_at = NOW()
  WHERE id = (p_buyer->>'id')::UUID
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: buyer';
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.archive_buyer(
  p_request_id UUID,
  p_request_hash TEXT,
  p_buyer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row buyers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE buyers SET is_active = FALSE, updated_at = NOW()
  WHERE id = p_buyer_id RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: buyer'; END IF;
  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.reactivate_buyer(
  p_request_id UUID,
  p_request_hash TEXT,
  p_buyer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row buyers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE buyers SET is_active = TRUE, updated_at = NOW()
  WHERE id = p_buyer_id RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: buyer'; END IF;
  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.record_customer_ledger_entry(
  p_request_id UUID,
  p_request_hash TEXT,
  p_entry JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_existing customer_transactions%ROWTYPE;
  v_row customer_transactions%ROWTYPE;
  v_entry_type TEXT;
  v_customer customers%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();
  v_entry_type := p_entry->>'entry_type';

  SELECT * INTO v_existing FROM customer_transactions WHERE request_id = p_request_id;
  IF FOUND THEN
    IF v_existing.request_hash <> p_request_hash THEN PERFORM public.idempotency_conflict(); END IF;
    RETURN to_jsonb(v_existing);
  END IF;

  IF v_entry_type NOT IN (
    'OPENING_BALANCE',
    'BALANCE_INCREASE_ADJUSTMENT',
    'BALANCE_DECREASE_ADJUSTMENT'
  ) THEN
    RAISE EXCEPTION 'VALIDATION_ERROR: unsupported customer ledger entry_type';
  END IF;

  SELECT * INTO v_customer FROM customers WHERE id = (p_entry->>'customer_id')::UUID FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: customer'; END IF;
  IF NOT v_customer.is_active THEN RAISE EXCEPTION 'CUSTOMER_ARCHIVED'; END IF;

  INSERT INTO customer_transactions (
    customer_id, request_id, request_hash, opening_balance_customer_id,
    entry_type, amount, occurred_on, notes, created_by_user_id
  ) VALUES (
    v_customer.id,
    p_request_id,
    p_request_hash,
    CASE WHEN v_entry_type = 'OPENING_BALANCE' THEN v_customer.id ELSE NULL END,
    v_entry_type,
    (p_entry->>'amount')::NUMERIC,
    (p_entry->>'occurred_on')::DATE,
    p_entry->>'notes',
    v_user
  ) RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.record_batch_collections(
  p_request_id UUID,
  p_request_hash TEXT,
  p_batch JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_entry JSONB;
  v_entry_count INTEGER := 0;
  v_total NUMERIC(14,2) := 0;
  v_affected INTEGER;
  v_request_id UUID;
  v_customer customers%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();

  IF EXISTS (
    SELECT 1 FROM customer_transactions
    WHERE notes LIKE '\_\_batch\_\_|' || p_request_id::TEXT || '|%' ESCAPE '\'
      AND request_hash <> p_request_hash
  ) THEN
    PERFORM public.idempotency_conflict();
  END IF;

  IF EXISTS (
    SELECT 1 FROM customer_transactions
    WHERE notes = '__batch__|' || p_request_id::TEXT || '|' || p_request_hash
  ) THEN
    SELECT COUNT(*), COALESCE(SUM(amount), 0), COUNT(DISTINCT customer_id)
      INTO v_entry_count, v_total, v_affected
    FROM customer_transactions
    WHERE notes = '__batch__|' || p_request_id::TEXT || '|' || p_request_hash;
    RETURN jsonb_build_object(
      'request_id', p_request_id::TEXT,
      'entry_count', v_entry_count,
      'total_amount', v_total,
      'affected_customers', v_affected
    );
  END IF;

  FOR v_entry IN SELECT * FROM jsonb_array_elements(COALESCE(p_batch->'entries', '[]'::JSONB))
  LOOP
    SELECT * INTO v_customer FROM customers WHERE id = (v_entry->>'customer_id')::UUID FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: customer'; END IF;
    IF NOT v_customer.is_active THEN RAISE EXCEPTION 'CUSTOMER_ARCHIVED'; END IF;

    v_request_id := gen_random_uuid();
    INSERT INTO customer_transactions (
      customer_id, request_id, request_hash, entry_type, amount, occurred_on,
      notes, created_by_user_id
    ) VALUES (
      v_customer.id,
      v_request_id,
      p_request_hash,
      'COLLECTION',
      (v_entry->>'amount')::NUMERIC,
      (v_entry->>'occurred_on')::DATE,
      '__batch__|' || p_request_id::TEXT || '|' || p_request_hash,
      v_user
    );
    v_entry_count := v_entry_count + 1;
    v_total := v_total + (v_entry->>'amount')::NUMERIC;
  END LOOP;

  SELECT COUNT(DISTINCT value->>'customer_id') INTO v_affected
  FROM jsonb_array_elements(COALESCE(p_batch->'entries', '[]'::JSONB));

  RETURN jsonb_build_object(
    'request_id', p_request_id::TEXT,
    'entry_count', v_entry_count,
    'total_amount', v_total,
    'affected_customers', COALESCE(v_affected, 0)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.record_buyer_ledger_entry(
  p_request_id UUID,
  p_request_hash TEXT,
  p_entry JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_existing buyer_transactions%ROWTYPE;
  v_row buyer_transactions%ROWTYPE;
  v_entry_type TEXT;
  v_buyer buyers%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();
  v_entry_type := p_entry->>'entry_type';

  SELECT * INTO v_existing FROM buyer_transactions WHERE request_id = p_request_id;
  IF FOUND THEN
    IF v_existing.request_hash <> p_request_hash THEN PERFORM public.idempotency_conflict(); END IF;
    RETURN to_jsonb(v_existing);
  END IF;

  IF v_entry_type NOT IN (
    'OPENING_PAYABLE',
    'PURCHASE_AMOUNT',
    'PAYMENT_MADE',
    'PAYABLE_INCREASE_ADJUSTMENT',
    'PAYABLE_DECREASE_ADJUSTMENT'
  ) THEN
    RAISE EXCEPTION 'VALIDATION_ERROR: unsupported buyer ledger entry_type';
  END IF;

  SELECT * INTO v_buyer FROM buyers WHERE id = (p_entry->>'buyer_id')::UUID FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: buyer'; END IF;
  IF NOT v_buyer.is_active THEN RAISE EXCEPTION 'BUYER_ARCHIVED'; END IF;

  INSERT INTO buyer_transactions (
    buyer_id, request_id, request_hash, entry_type, amount, occurred_at,
    notes, created_by_user_id
  ) VALUES (
    v_buyer.id,
    p_request_id,
    p_request_hash,
    v_entry_type,
    (p_entry->>'amount')::NUMERIC,
    (p_entry->>'occurred_at')::TIMESTAMPTZ,
    p_entry->>'notes',
    v_user
  ) RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_buyer(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_buyer(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.archive_buyer(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reactivate_buyer(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_customer_ledger_entry(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_batch_collections(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_buyer_ledger_entry(UUID, TEXT, JSONB) TO authenticated;
