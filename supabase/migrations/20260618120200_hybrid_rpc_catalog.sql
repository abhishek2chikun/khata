-- Catalog seed and master-data RPCs

CREATE OR REPLACE FUNCTION public.seed_master_catalog(
  p_catalog JSONB,
  p_allow_stock_reset BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_version INTEGER;
  v_buyer JSONB;
  v_product JSONB;
  v_buyer_count INTEGER := 0;
  v_product_count INTEGER := 0;
  v_existing INTEGER;
BEGIN
  v_user := public.require_authenticated();

  v_version := COALESCE((p_catalog->>'catalog_version')::INTEGER, 0);
  IF v_version <= 0 THEN
    RAISE EXCEPTION 'VALIDATION_ERROR: catalog_version required';
  END IF;

  SELECT COUNT(*) INTO v_existing FROM catalog_seed_runs;
  IF v_existing > 0 AND NOT p_allow_stock_reset THEN
    -- Idempotent reseed: upsert buyers/products without resetting mutable stock unless flagged
    NULL;
  END IF;

  FOR v_buyer IN SELECT * FROM jsonb_array_elements(COALESCE(p_catalog->'buyers', '[]'::JSONB))
  LOOP
    INSERT INTO buyers (
      id, name, address, state, state_code, phone, gstin, whatsapp_number, is_active, created_at, updated_at
    ) VALUES (
      (v_buyer->>'id')::UUID,
      v_buyer->>'name',
      COALESCE(v_buyer->>'address', ''),
      v_buyer->>'state',
      v_buyer->>'state_code',
      v_buyer->>'phone',
      v_buyer->>'gstin',
      v_buyer->>'whatsapp_number',
      COALESCE((v_buyer->>'is_active')::BOOLEAN, TRUE),
      COALESCE((v_buyer->>'created_at')::TIMESTAMPTZ, NOW()),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      address = EXCLUDED.address,
      state = EXCLUDED.state,
      state_code = EXCLUDED.state_code,
      phone = EXCLUDED.phone,
      gstin = EXCLUDED.gstin,
      whatsapp_number = EXCLUDED.whatsapp_number,
      is_active = EXCLUDED.is_active,
      updated_at = NOW();
    v_buyer_count := v_buyer_count + 1;
  END LOOP;

  FOR v_product IN SELECT * FROM jsonb_array_elements(COALESCE(p_catalog->'products', '[]'::JSONB))
  LOOP
    INSERT INTO products (
      id, item_number, item_name, category, company_name, buyer_id,
      buying_price, selling_price, unit, hsn_code, gst_rate,
      quantity_on_hand, low_stock_threshold, is_active, created_at, updated_at
    ) VALUES (
      (v_product->>'id')::UUID,
      v_product->>'item_number',
      v_product->>'item_name',
      v_product->>'category',
      v_product->>'company_name',
      NULLIF(v_product->>'buyer_id', '')::UUID,
      (v_product->>'buying_price')::NUMERIC,
      (v_product->>'selling_price')::NUMERIC,
      v_product->>'unit',
      v_product->>'hsn_code',
      (v_product->>'gst_rate')::NUMERIC,
      CASE WHEN v_existing = 0 OR p_allow_stock_reset
        THEN (v_product->>'quantity_on_hand')::NUMERIC
        ELSE products.quantity_on_hand
      END,
      COALESCE((v_product->>'low_stock_threshold')::NUMERIC, 0),
      COALESCE((v_product->>'is_active')::BOOLEAN, TRUE),
      COALESCE((v_product->>'created_at')::TIMESTAMPTZ, NOW()),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      item_number = EXCLUDED.item_number,
      item_name = EXCLUDED.item_name,
      category = EXCLUDED.category,
      company_name = EXCLUDED.company_name,
      buyer_id = EXCLUDED.buyer_id,
      buying_price = EXCLUDED.buying_price,
      selling_price = EXCLUDED.selling_price,
      unit = EXCLUDED.unit,
      hsn_code = EXCLUDED.hsn_code,
      gst_rate = EXCLUDED.gst_rate,
      quantity_on_hand = CASE WHEN p_allow_stock_reset THEN EXCLUDED.quantity_on_hand ELSE products.quantity_on_hand END,
      low_stock_threshold = EXCLUDED.low_stock_threshold,
      is_active = EXCLUDED.is_active,
      updated_at = NOW();
    v_product_count := v_product_count + 1;
  END LOOP;

  INSERT INTO catalog_seed_runs (catalog_version, product_count, buyer_count, allow_stock_reset)
  VALUES (v_version, v_product_count, v_buyer_count, p_allow_stock_reset);

  RETURN jsonb_build_object(
    'catalog_version', v_version,
    'buyer_count', v_buyer_count,
    'product_count', v_product_count,
    'allow_stock_reset', p_allow_stock_reset
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_company_profile(
  p_request_id UUID,
  p_request_hash TEXT,
  p_profile JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_id UUID;
  v_row company_profiles%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();

  UPDATE company_profiles SET is_active = FALSE, updated_at = NOW() WHERE is_active = TRUE;

  v_id := COALESCE((p_profile->>'id')::UUID, gen_random_uuid());
  INSERT INTO company_profiles (
    id, name, address, city, state, state_code, gstin, gst_flag,
    phone, email, bank_name, bank_account, bank_ifsc, bank_branch, jurisdiction,
    is_active, created_at, updated_at
  ) VALUES (
    v_id,
    p_profile->>'name',
    p_profile->>'address',
    p_profile->>'city',
    p_profile->>'state',
    p_profile->>'state_code',
    p_profile->>'gstin',
    COALESCE((p_profile->>'gst_flag')::BOOLEAN, FALSE),
    p_profile->>'phone',
    p_profile->>'email',
    p_profile->>'bank_name',
    p_profile->>'bank_account',
    p_profile->>'bank_ifsc',
    p_profile->>'bank_branch',
    p_profile->>'jurisdiction',
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    state_code = EXCLUDED.state_code,
    gstin = EXCLUDED.gstin,
    gst_flag = EXCLUDED.gst_flag,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    bank_name = EXCLUDED.bank_name,
    bank_account = EXCLUDED.bank_account,
    bank_ifsc = EXCLUDED.bank_ifsc,
    bank_branch = EXCLUDED.bank_branch,
    jurisdiction = EXCLUDED.jurisdiction,
    is_active = TRUE,
    updated_at = NOW()
  RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.create_product(
  p_request_id UUID,
  p_request_hash TEXT,
  p_product JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_existing products%ROWTYPE;
  v_row products%ROWTYPE;
  v_opening_stock NUMERIC(14,3);
BEGIN
  v_user := public.require_authenticated();

  SELECT * INTO v_existing FROM products WHERE id = (p_product->>'id')::UUID;
  IF FOUND THEN
    IF EXISTS (SELECT 1 FROM stock_movements WHERE request_id = p_request_id) THEN
      SELECT * INTO v_row FROM products WHERE id = v_existing.id;
      RETURN to_jsonb(v_row);
  END IF;
    PERFORM public.idempotency_conflict();
  END IF;

  v_opening_stock := COALESCE((p_product->>'quantity_on_hand')::NUMERIC, 0);

  INSERT INTO products (
    id, item_number, item_name, category, company_name, buyer_id,
    buying_price, selling_price, unit, hsn_code, gst_rate,
    quantity_on_hand, low_stock_threshold, is_active, created_at, updated_at
  ) VALUES (
    COALESCE((p_product->>'id')::UUID, gen_random_uuid()),
    p_product->>'item_number',
    p_product->>'item_name',
    p_product->>'category',
    p_product->>'company_name',
    NULLIF(p_product->>'buyer_id', '')::UUID,
    (p_product->>'buying_price')::NUMERIC,
    (p_product->>'selling_price')::NUMERIC,
    p_product->>'unit',
    p_product->>'hsn_code',
    (p_product->>'gst_rate')::NUMERIC,
    v_opening_stock,
    COALESCE((p_product->>'low_stock_threshold')::NUMERIC, 0),
    TRUE,
    NOW(),
    NOW()
  ) RETURNING * INTO v_row;

  IF v_opening_stock <> 0 THEN
    INSERT INTO stock_movements (
      product_id, movement_type, quantity_delta, request_hash, reason, created_by_user_id
    ) VALUES (
      v_row.id, 'OPENING', v_opening_stock, p_request_hash, 'Opening stock', v_user
    );
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_product(
  p_request_id UUID,
  p_request_hash TEXT,
  p_product JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_row products%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();

  UPDATE products SET
    item_name = COALESCE(p_product->>'item_name', item_name),
    category = COALESCE(p_product->>'category', category),
    company_name = COALESCE(p_product->>'company_name', company_name),
    buyer_id = COALESCE(NULLIF(p_product->>'buyer_id', '')::UUID, buyer_id),
    buying_price = COALESCE((p_product->>'buying_price')::NUMERIC, buying_price),
    selling_price = COALESCE((p_product->>'selling_price')::NUMERIC, selling_price),
    unit = COALESCE(p_product->>'unit', unit),
    hsn_code = COALESCE(p_product->>'hsn_code', hsn_code),
    gst_rate = COALESCE((p_product->>'gst_rate')::NUMERIC, gst_rate),
    low_stock_threshold = COALESCE((p_product->>'low_stock_threshold')::NUMERIC, low_stock_threshold),
    updated_at = NOW()
  WHERE id = (p_product->>'id')::UUID
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: product';
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.archive_product(p_request_id UUID, p_request_hash TEXT, p_product_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row products%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE products SET is_active = FALSE, updated_at = NOW()
  WHERE id = p_product_id RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: product'; END IF;
  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.reactivate_product(p_request_id UUID, p_request_hash TEXT, p_product_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row products%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE products SET is_active = TRUE, updated_at = NOW()
  WHERE id = p_product_id RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: product'; END IF;
  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.create_customer(
  p_request_id UUID,
  p_request_hash TEXT,
  p_customer JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_row customers%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();

  IF EXISTS (SELECT 1 FROM customer_transactions WHERE request_id = p_request_id) THEN
    SELECT c.* INTO v_row FROM customers c
    JOIN customer_transactions ct ON ct.customer_id = c.id
    WHERE ct.request_id = p_request_id LIMIT 1;
    IF FOUND THEN RETURN to_jsonb(v_row); END IF;
  END IF;

  INSERT INTO customers (
    id, name, address, state, state_code, phone, gstin, whatsapp_number, is_active, created_at, updated_at
  ) VALUES (
    COALESCE((p_customer->>'id')::UUID, gen_random_uuid()),
    p_customer->>'name',
    p_customer->>'address',
    p_customer->>'state',
    p_customer->>'state_code',
    p_customer->>'phone',
    p_customer->>'gstin',
    p_customer->>'whatsapp_number',
    TRUE,
    NOW(),
    NOW()
  ) RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_customer(
  p_request_id UUID,
  p_request_hash TEXT,
  p_customer JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row customers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE customers SET
    name = COALESCE(p_customer->>'name', name),
    address = COALESCE(p_customer->>'address', address),
    state = COALESCE(p_customer->>'state', state),
    state_code = COALESCE(p_customer->>'state_code', state_code),
    phone = COALESCE(p_customer->>'phone', phone),
    gstin = COALESCE(p_customer->>'gstin', gstin),
    whatsapp_number = COALESCE(p_customer->>'whatsapp_number', whatsapp_number),
    updated_at = NOW()
  WHERE id = (p_customer->>'id')::UUID
  RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: customer'; END IF;
  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.archive_customer(p_request_id UUID, p_request_hash TEXT, p_customer_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row customers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE customers SET is_active = FALSE, updated_at = NOW() WHERE id = p_customer_id RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: customer'; END IF;
  RETURN to_jsonb(v_row);
END; $$;

CREATE OR REPLACE FUNCTION public.reactivate_customer(p_request_id UUID, p_request_hash TEXT, p_customer_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row customers%ROWTYPE;
BEGIN
  PERFORM public.require_authenticated();
  UPDATE customers SET is_active = TRUE, updated_at = NOW() WHERE id = p_customer_id RETURNING * INTO v_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: customer'; END IF;
  RETURN to_jsonb(v_row);
END; $$;

GRANT EXECUTE ON FUNCTION public.seed_master_catalog(JSONB, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_company_profile(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_product(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_product(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.archive_product(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reactivate_product(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_customer(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_customer(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.archive_customer(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reactivate_customer(UUID, TEXT, UUID) TO authenticated;
