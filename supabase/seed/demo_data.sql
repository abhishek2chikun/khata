-- Minimal demo seed for hybrid manual testing (run after migrations)

INSERT INTO buyers (id, name, address, is_active, created_at, updated_at)
VALUES (
  '55555555-5555-5555-5555-555555555555',
  'Demo Supplier',
  'Supplier Address',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();

INSERT INTO company_profiles (
  id, name, address, city, state, state_code, gstin, gst_flag,
  phone, email, is_active, created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Demo Company',
  '123 Business Street',
  'Mumbai',
  'Maharashtra',
  '27',
  '27AABCU9603R1ZX',
  true,
  '+919876543210',
  'demo@company.com',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();

INSERT INTO customers (id, name, address, state, state_code, phone, is_active, created_at, updated_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Retail Shop A', 'Market Road', 'Maharashtra', '27', '9876543210', true, NOW(), NOW()),
  ('22222222-2222-2222-2222-222222222222', 'Retail Shop B', 'Main Street', 'Gujarat', '24', '9876543211', true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();

INSERT INTO products (
  id, item_number, item_name, category, company_name,
  buying_price, selling_price, unit, hsn_code, gst_rate,
  quantity_on_hand, low_stock_threshold, is_active, created_at, updated_at
) VALUES
  ('33333333-3333-3333-3333-333333333333', 'DEMO-0001', 'Sample Product 1', 'General', 'Demo Supplier',
   100.000, 120.000, 'pcs', '12345678', 18.00, 100, 10, true, NOW(), NOW()),
  ('44444444-4444-4444-4444-444444444444', 'DEMO-0002', 'Sample Product 2', 'General', 'Demo Supplier',
   50.000, 60.000, 'pcs', '87654321', 18.00, 50, 5, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  item_name = EXCLUDED.item_name,
  quantity_on_hand = EXCLUDED.quantity_on_hand,
  updated_at = NOW();
