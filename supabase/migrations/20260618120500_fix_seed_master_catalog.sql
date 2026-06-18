-- Fix seed_master_catalog: invalid products reference in INSERT VALUES clause

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
  v_product_id UUID;
  v_existing_qty NUMERIC(14,3);
BEGIN
  v_user := public.require_authenticated();

  v_version := COALESCE((p_catalog->>'catalog_version')::INTEGER, 0);
  IF v_version <= 0 THEN
    RAISE EXCEPTION 'VALIDATION_ERROR: catalog_version required';
  END IF;

  SELECT COUNT(*) INTO v_existing FROM catalog_seed_runs;
  IF v_existing > 0 AND NOT p_allow_stock_reset THEN
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
    v_product_id := (v_product->>'id')::UUID;
    v_existing_qty := NULL;
    IF v_existing > 0 AND NOT p_allow_stock_reset THEN
      SELECT quantity_on_hand
      INTO v_existing_qty
      FROM products
      WHERE id = v_product_id;
    END IF;

    INSERT INTO products (
      id, item_number, item_name, category, company_name, buyer_id,
      buying_price, selling_price, unit, hsn_code, gst_rate,
      quantity_on_hand, low_stock_threshold, is_active, created_at, updated_at
    ) VALUES (
      v_product_id,
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
      CASE
        WHEN v_existing = 0 OR p_allow_stock_reset OR v_existing_qty IS NULL
          THEN (v_product->>'quantity_on_hand')::NUMERIC
        ELSE v_existing_qty
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
      quantity_on_hand = CASE
        WHEN p_allow_stock_reset THEN EXCLUDED.quantity_on_hand
        ELSE products.quantity_on_hand
      END,
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

GRANT EXECUTE ON FUNCTION public.seed_master_catalog(JSONB, BOOLEAN) TO authenticated;
