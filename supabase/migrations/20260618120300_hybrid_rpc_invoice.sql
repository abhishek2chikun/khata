-- Invoice, collection, stock, and buyer RPCs

CREATE OR REPLACE FUNCTION public.create_invoice(
  p_request_id UUID,
  p_request_hash TEXT,
  p_invoice JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_existing invoices%ROWTYPE;
  v_customer customers%ROWTYPE;
  v_company company_profiles%ROWTYPE;
  v_invoice invoices%ROWTYPE;
  v_item JSONB;
  v_product products%ROWTYPE;
  v_qty NUMERIC(14,3);
  v_line_num INTEGER := 0;
  v_invoice_id UUID;
  v_items JSONB := '[]'::JSONB;
  v_stock JSONB := '[]'::JSONB;
  v_ledger JSONB := '[]'::JSONB;
BEGIN
  v_user := public.require_authenticated();

  SELECT * INTO v_existing FROM invoices WHERE request_id = p_request_id;
  IF FOUND THEN
    IF v_existing.request_hash <> p_request_hash THEN
      PERFORM public.idempotency_conflict();
    END IF;
    RETURN jsonb_build_object(
      'invoice', to_jsonb(v_existing),
      'items', (SELECT COALESCE(jsonb_agg(to_jsonb(ii) ORDER BY ii.line_number), '[]'::JSONB)
                FROM invoice_items ii WHERE ii.invoice_id = v_existing.id),
      'stock_movements', (SELECT COALESCE(jsonb_agg(to_jsonb(sm)), '[]'::JSONB)
                          FROM stock_movements sm WHERE sm.invoice_id = v_existing.id),
      'customer_transactions', (SELECT COALESCE(jsonb_agg(to_jsonb(ct)), '[]'::JSONB)
                                FROM customer_transactions ct WHERE ct.invoice_id = v_existing.id)
    );
  END IF;

  SELECT * INTO v_customer FROM customers WHERE id = (p_invoice->>'customer_id')::UUID AND is_active = TRUE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: customer'; END IF;

  SELECT * INTO v_company FROM company_profiles WHERE is_active = TRUE LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'SETUP_REQUIRED: company profile'; END IF;

  -- Validate stock for all lines first
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_invoice->'items')
  LOOP
    v_qty := (v_item->>'quantity')::NUMERIC;
    IF v_qty <= 0 OR v_qty <> TRUNC(v_qty) THEN
      RAISE EXCEPTION 'VALIDATION_ERROR: quantity must be a positive whole number';
    END IF;
    SELECT * INTO v_product FROM products WHERE id = (v_item->>'product_id')::UUID AND is_active = TRUE FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: product %', v_item->>'product_id'; END IF;
    IF v_product.quantity_on_hand < v_qty THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK: %', v_product.item_name;
    END IF;
  END LOOP;

  v_invoice_id := COALESCE((p_invoice->>'id')::UUID, gen_random_uuid());

  INSERT INTO invoices (
    id, request_id, request_hash, customer_id,
    customer_name, customer_address, customer_state, customer_state_code,
    customer_phone, customer_whatsapp_number, customer_gstin,
    place_of_supply_state, place_of_supply_state_code,
    company_name, company_address, company_city, company_state, company_state_code,
    company_gstin, company_phone, company_email,
    company_bank_name, company_bank_account, company_bank_ifsc, company_bank_branch, company_jurisdiction,
    gst_flag, invoice_date, invoice_datetime, tax_regime, status,
    payment_state, paid_amount,
    subtotal, discount_total, taxable_total, gst_total, grand_total,
    notes, created_by_user_id, created_at, updated_at
  ) VALUES (
    v_invoice_id,
    p_request_id,
    p_request_hash,
    v_customer.id,
    COALESCE(p_invoice->>'customer_name', v_customer.name),
    COALESCE(p_invoice->>'customer_address', v_customer.address),
    COALESCE(p_invoice->>'customer_state', v_customer.state),
    COALESCE(p_invoice->>'customer_state_code', v_customer.state_code),
    COALESCE(p_invoice->>'customer_phone', v_customer.phone),
    COALESCE(p_invoice->>'customer_whatsapp_number', v_customer.whatsapp_number),
    COALESCE(p_invoice->>'customer_gstin', v_customer.gstin),
    p_invoice->>'place_of_supply_state',
    p_invoice->>'place_of_supply_state_code',
    COALESCE(p_invoice->>'company_name', v_company.name),
    COALESCE(p_invoice->>'company_address', v_company.address),
    COALESCE(p_invoice->>'company_city', v_company.city),
    COALESCE(p_invoice->>'company_state', v_company.state),
    COALESCE(p_invoice->>'company_state_code', v_company.state_code),
    CASE WHEN COALESCE((p_invoice->>'gst_flag')::BOOLEAN, v_company.gst_flag) THEN v_company.gstin ELSE NULL END,
    v_company.phone, v_company.email,
    v_company.bank_name, v_company.bank_account, v_company.bank_ifsc, v_company.bank_branch, v_company.jurisdiction,
    COALESCE((p_invoice->>'gst_flag')::BOOLEAN, v_company.gst_flag),
    (p_invoice->>'invoice_date')::DATE,
    (p_invoice->>'invoice_datetime')::TIMESTAMPTZ,
    p_invoice->>'tax_regime',
    'ACTIVE',
    p_invoice->>'payment_state',
    (p_invoice->>'paid_amount')::NUMERIC,
    (p_invoice->>'subtotal')::NUMERIC,
    (p_invoice->>'discount_total')::NUMERIC,
    (p_invoice->>'taxable_total')::NUMERIC,
    (p_invoice->>'gst_total')::NUMERIC,
    (p_invoice->>'grand_total')::NUMERIC,
    p_invoice->>'notes',
    v_user,
    NOW(),
    NOW()
  ) RETURNING * INTO v_invoice;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_invoice->'items')
  LOOP
    v_line_num := v_line_num + 1;
    v_qty := (v_item->>'quantity')::NUMERIC;
    SELECT * INTO v_product FROM products WHERE id = (v_item->>'product_id')::UUID FOR UPDATE;

    INSERT INTO invoice_items (
      invoice_id, product_id, line_number,
      product_item_number, product_item_name, product_category, product_buyer_id, product_company_name, product_hsn_code,
      buying_price, selling_price, unit,
      product_name, product_code, company, category,
      quantity, pricing_mode, entered_unit_price, unit_price_excl_tax, unit_price_incl_tax,
      gst_rate, cgst_rate, sgst_rate, igst_rate,
      discount_percent, discount_amount, taxable_amount, gst_amount,
      cgst_amount, sgst_amount, igst_amount, line_total,
      revenue_amount, buying_amount, profit_amount
    ) VALUES (
      v_invoice.id, v_product.id, v_line_num,
      v_product.item_number, v_product.item_name, v_product.category, v_product.buyer_id, v_product.company_name, v_product.hsn_code,
      v_product.buying_price, v_product.selling_price, v_product.unit,
      v_product.item_name, v_product.item_number, v_product.company_name, v_product.category,
      v_qty,
      v_item->>'pricing_mode',
      (v_item->>'entered_unit_price')::NUMERIC,
      (v_item->>'unit_price_excl_tax')::NUMERIC,
      (v_item->>'unit_price_incl_tax')::NUMERIC,
      (v_item->>'gst_rate')::NUMERIC,
      (v_item->>'cgst_rate')::NUMERIC,
      (v_item->>'sgst_rate')::NUMERIC,
      (v_item->>'igst_rate')::NUMERIC,
      (v_item->>'discount_percent')::NUMERIC,
      (v_item->>'discount_amount')::NUMERIC,
      (v_item->>'taxable_amount')::NUMERIC,
      (v_item->>'gst_amount')::NUMERIC,
      (v_item->>'cgst_amount')::NUMERIC,
      (v_item->>'sgst_amount')::NUMERIC,
      (v_item->>'igst_amount')::NUMERIC,
      (v_item->>'line_total')::NUMERIC,
      (v_item->>'revenue_amount')::NUMERIC,
      (v_item->>'buying_amount')::NUMERIC,
      (v_item->>'profit_amount')::NUMERIC
    );

    INSERT INTO stock_movements (
      product_id, invoice_id, movement_type, quantity_delta, reason, created_by_user_id
    ) VALUES (
      v_product.id, v_invoice.id, 'INVOICE_SALE', -v_qty,
      'Invoice ' || v_invoice.invoice_number::TEXT, v_user
    );

    UPDATE products SET quantity_on_hand = quantity_on_hand - v_qty, updated_at = NOW()
    WHERE id = v_product.id;
  END LOOP;

  INSERT INTO customer_transactions (
    customer_id, invoice_id, entry_type, amount, occurred_on, notes, created_by_user_id
  ) VALUES (
    v_invoice.customer_id, v_invoice.id, 'CREDIT_SALE', v_invoice.grand_total,
    v_invoice.invoice_date, 'Invoice ' || v_invoice.invoice_number::TEXT, v_user
  );

  IF v_invoice.paid_amount > 0 THEN
    INSERT INTO customer_transactions (
      customer_id, invoice_id, entry_type, amount, occurred_on, notes, created_by_user_id
    ) VALUES (
      v_invoice.customer_id, v_invoice.id, 'COLLECTION', v_invoice.paid_amount,
      v_invoice.invoice_date, 'Invoice ' || v_invoice.invoice_number::TEXT || ' collection', v_user
    );
  END IF;

  v_items := (SELECT COALESCE(jsonb_agg(to_jsonb(ii) ORDER BY ii.line_number), '[]'::JSONB)
              FROM invoice_items ii WHERE ii.invoice_id = v_invoice.id);
  v_stock := (SELECT COALESCE(jsonb_agg(to_jsonb(sm)), '[]'::JSONB)
              FROM stock_movements sm WHERE sm.invoice_id = v_invoice.id);
  v_ledger := (SELECT COALESCE(jsonb_agg(to_jsonb(ct)), '[]'::JSONB)
               FROM customer_transactions ct WHERE ct.invoice_id = v_invoice.id);

  RETURN jsonb_build_object(
    'invoice', to_jsonb(v_invoice),
    'items', v_items,
    'stock_movements', v_stock,
    'customer_transactions', v_ledger
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_invoice(
  p_invoice_id UUID,
  p_cancel_request_id UUID,
  p_cancel_request_hash TEXT,
  p_cancel_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_invoice invoices%ROWTYPE;
  v_item invoice_items%ROWTYPE;
  v_product products%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();

  SELECT * INTO v_invoice FROM invoices WHERE id = p_invoice_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: invoice'; END IF;

  IF v_invoice.status = 'CANCELED' THEN
    IF v_invoice.cancel_request_id = p_cancel_request_id THEN
      RETURN jsonb_build_object('invoice', to_jsonb(v_invoice));
    END IF;
    PERFORM public.idempotency_conflict();
  END IF;

  IF v_invoice.cancel_request_id IS NOT NULL AND v_invoice.cancel_request_id <> p_cancel_request_id THEN
    PERFORM public.idempotency_conflict();
  END IF;

  UPDATE invoices SET
    status = 'CANCELED',
    cancel_request_id = p_cancel_request_id,
    cancel_request_hash = p_cancel_request_hash,
    canceled_by_user_id = v_user,
    cancel_reason = p_cancel_reason,
    canceled_at = NOW(),
    updated_at = NOW()
  WHERE id = p_invoice_id
  RETURNING * INTO v_invoice;

  FOR v_item IN SELECT * FROM invoice_items WHERE invoice_id = p_invoice_id
  LOOP
    SELECT * INTO v_product FROM products WHERE id = v_item.product_id FOR UPDATE;
    INSERT INTO stock_movements (
      product_id, invoice_id, movement_type, quantity_delta, reason, created_by_user_id
    ) VALUES (
      v_product.id, p_invoice_id, 'INVOICE_CANCEL_REVERSAL', v_item.quantity,
      'Cancel invoice ' || v_invoice.invoice_number::TEXT, v_user
    );
    UPDATE products SET quantity_on_hand = quantity_on_hand + v_item.quantity, updated_at = NOW()
    WHERE id = v_product.id;
  END LOOP;

  INSERT INTO customer_transactions (
    customer_id, invoice_id, entry_type, amount, occurred_on, notes, created_by_user_id
  ) VALUES (
    v_invoice.customer_id, v_invoice.id, 'INVOICE_CANCEL_REVERSAL', v_invoice.grand_total,
    v_invoice.invoice_date, 'Cancel invoice ' || v_invoice.invoice_number::TEXT, v_user
  );

  IF v_invoice.paid_amount > 0 THEN
    INSERT INTO customer_transactions (
      customer_id, invoice_id, entry_type, amount, occurred_on, notes, created_by_user_id
    ) VALUES (
      v_invoice.customer_id, v_invoice.id, 'COLLECTION_REVERSAL', v_invoice.paid_amount,
      v_invoice.invoice_date, 'Cancel invoice ' || v_invoice.invoice_number::TEXT || ' collection reversal', v_user
    );
  END IF;

  RETURN jsonb_build_object(
    'invoice', to_jsonb(v_invoice),
    'stock_movements', (SELECT COALESCE(jsonb_agg(to_jsonb(sm)), '[]'::JSONB) FROM stock_movements sm WHERE sm.invoice_id = p_invoice_id AND sm.movement_type = 'INVOICE_CANCEL_REVERSAL'),
    'customer_transactions', (SELECT COALESCE(jsonb_agg(to_jsonb(ct)), '[]'::JSONB) FROM customer_transactions ct WHERE ct.invoice_id = p_invoice_id AND ct.entry_type IN ('INVOICE_CANCEL_REVERSAL', 'COLLECTION_REVERSAL'))
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.record_collection(
  p_request_id UUID,
  p_request_hash TEXT,
  p_collection JSONB
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
BEGIN
  v_user := public.require_authenticated();

  SELECT * INTO v_existing FROM customer_transactions WHERE request_id = p_request_id;
  IF FOUND THEN
    IF v_existing.request_hash <> p_request_hash THEN PERFORM public.idempotency_conflict(); END IF;
    RETURN to_jsonb(v_existing);
  END IF;

  INSERT INTO customer_transactions (
    customer_id, request_id, request_hash, entry_type, amount, occurred_on, notes, created_by_user_id
  ) VALUES (
    (p_collection->>'customer_id')::UUID,
    p_request_id,
    p_request_hash,
    'COLLECTION',
    (p_collection->>'amount')::NUMERIC,
    (p_collection->>'occurred_on')::DATE,
    p_collection->>'notes',
    v_user
  ) RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

CREATE OR REPLACE FUNCTION public.adjust_stock(
  p_request_id UUID,
  p_request_hash TEXT,
  p_adjustment JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID;
  v_product products%ROWTYPE;
  v_delta NUMERIC(14,3);
  v_row stock_movements%ROWTYPE;
BEGIN
  v_user := public.require_authenticated();
  v_delta := (p_adjustment->>'quantity_delta')::NUMERIC;

  IF EXISTS (SELECT 1 FROM stock_movements WHERE request_id = p_request_id) THEN
    SELECT * INTO v_row FROM stock_movements WHERE request_id = p_request_id;
    RETURN to_jsonb(v_row);
  END IF;

  SELECT * INTO v_product FROM products WHERE id = (p_adjustment->>'product_id')::UUID FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: product'; END IF;

  INSERT INTO stock_movements (
    product_id, request_id, request_hash, movement_type, quantity_delta, reason, created_by_user_id
  ) VALUES (
    v_product.id, p_request_id, p_request_hash, 'MANUAL_ADJUSTMENT', v_delta,
    p_adjustment->>'reason', v_user
  ) RETURNING * INTO v_row;

  UPDATE products SET quantity_on_hand = quantity_on_hand + v_delta, updated_at = NOW()
  WHERE id = v_product.id;

  RETURN jsonb_build_object('stock_movement', to_jsonb(v_row), 'product', to_jsonb(v_product));
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_invoice(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_invoice(UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_collection(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_stock(UUID, TEXT, JSONB) TO authenticated;
