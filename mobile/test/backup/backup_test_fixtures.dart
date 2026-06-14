import 'package:drift/drift.dart' show Value;
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;

Future<void> seedRoundTripData(
  db.LocalDatabase database, {
  String productId = 'product-0001',
}) async {
  await database.into(database.localUsers).insert(
        db.LocalUsersCompanion.insert(
          id: 'local-system-user',
          username: 'system-$productId',
          passwordHash: 'hash',
          salt: 'salt',
          passwordHashVersion: 1,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
          displayName: const Value('System'),
        ),
      );
  await database.into(database.products).insert(
        db.ProductsCompanion.insert(
          id: productId,
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-$productId',
          buyerId: const Value('buyer-0001'),
          buyingPrice: '99.9900',
          sellingPrice: '123.4500',
          unit: const Value('box'),
          gstRate: '18.000',
          quantityOnHand: '7.500',
          lowStockThreshold: '2.00',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
  await database.into(database.customers).insert(
        db.CustomersCompanion.insert(
          id: 'customer-0001',
          name: 'Acme Stores $productId',
          address: '1 Market Road',
          state: const Value('Maharashtra'),
          stateCode: const Value('27'),
          phone: Value('9999$productId'),
          gstin: const Value('27ABCDE1234F1Z5'),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
  await database.into(database.buyers).insert(
        db.BuyersCompanion.insert(
          id: 'buyer-0001',
          name: 'Global Suppliers $productId',
          address: '9 Wholesale Market',
          state: const Value('Maharashtra'),
          stateCode: const Value('27'),
          phone: Value('8888$productId'),
          gstin: const Value('27ABCDE1234F1Z5'),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
  await database.into(database.buyerTransactions).insert(
        db.BuyerTransactionsCompanion.insert(
          id: 'buyer-transaction-0001',
          buyerId: 'buyer-0001',
          requestId: Value('buyer-request-$productId'),
          requestHash: const Value('buyer-request-hash'),
          entryType: 'PURCHASE_AMOUNT',
          amount: '123.45',
          occurredAt: '2026-01-02T10:30:00+05:30',
          notes: const Value('Purchase bill'),
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-02T05:00:00.000Z',
        ),
      );
  await database.into(database.invoices).insert(
        db.InvoicesCompanion.insert(
          id: 'invoice-0001',
          requestId: 'request-$productId',
          requestHash: 'request-hash',
          invoiceNumber: 1,
          customerId: 'customer-0001',
          customerName: 'Acme Stores $productId',
          customerAddress: '1 Market Road',
          customerState: const Value('Maharashtra'),
          customerStateCode: const Value('27'),
          customerPhone: Value('9999$productId'),
          customerGstin: const Value('27ABCDE1234F1Z5'),
          placeOfSupplyState: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          companyName: 'Khata Traders',
          companyAddress: '10 Market Road',
          companyCity: 'Mumbai',
          companyState: 'Maharashtra',
          companyStateCode: '27',
          invoiceDate: '2026-01-10',
          taxRegime: 'INTRA_STATE',
          status: 'ACTIVE',
          paymentMode: 'CREDIT',
          subtotal: '123.4500',
          discountTotal: '0.0000',
          taxableTotal: '123.4500',
          gstTotal: '22.2210',
          grandTotal: '145.6710',
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-10T00:00:00.000Z',
        ),
      );
  await database.into(database.invoiceItems).insert(
        db.InvoiceItemsCompanion.insert(
          id: 'invoice-item-0001',
          invoiceId: 'invoice-0001',
          productId: productId,
          lineNumber: 1,
          productName: 'Blue Pen',
          productCode: 'PEN-$productId',
          productItemNumber: Value('PEN-$productId'),
          productItemName: const Value('Blue Pen'),
          productCategory: const Value('Pens'),
          productCompanyName: const Value('Acme'),
          productBuyerId: const Value('buyer-0001'),
          buyingPrice: const Value('99.9900'),
          sellingPrice: const Value('145.6710'),
          company: 'Acme',
          category: 'Pens',
          quantity: '1.250',
          pricingMode: 'PRE_TAX',
          enteredUnitPrice: '123.4500',
          unitPriceExclTax: '123.4500',
          unitPriceInclTax: '145.6710',
          gstRate: '18.000',
          cgstRate: '9.000',
          sgstRate: '9.000',
          igstRate: '0.000',
          discountPercent: '0.000',
          discountAmount: '0.0000',
          taxableAmount: '123.4500',
          gstAmount: '22.2210',
          cgstAmount: '11.1105',
          sgstAmount: '11.1105',
          igstAmount: '0.0000',
          lineTotal: '145.6710',
        ),
      );
  await database.into(database.customerTransactions).insert(
        db.CustomerTransactionsCompanion.insert(
          id: 'customer-transaction-0001',
          customerId: 'customer-0001',
          invoiceId: const Value('invoice-0001'),
          entryType: 'CREDIT_SALE',
          amount: '145.6710',
          occurredOn: '2026-01-10',
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-10T00:00:00.000Z',
        ),
      );
}
