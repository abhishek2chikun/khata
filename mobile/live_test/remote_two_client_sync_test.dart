import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_invoices_service.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_rpc_client.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_sync_service.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_write_services.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_invoices_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
const _primaryEmail = String.fromEnvironment('PRIMARY_EMAIL');
const _primaryPassword = String.fromEnvironment('PRIMARY_PASSWORD');
const _secondaryEmail = String.fromEnvironment('SECONDARY_EMAIL');
const _secondaryPassword = String.fromEnvironment('SECONDARY_PASSWORD');

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('two authenticated clients create, sync, cancel, and resync', () async {
    _requireConfiguration();

    final primaryClient = _client(_anonKey);
    final secondaryClient = _client(_anonKey);
    final adminClient = _client(_serviceRoleKey);
    final primaryDb = LocalDatabase.memory();
    final secondaryDb = LocalDatabase.memory();
    final created = _CreatedRows();

    try {
      await primaryClient.auth.signInWithPassword(
        email: _primaryEmail,
        password: _primaryPassword,
      );
      await secondaryClient.auth.signInWithPassword(
        email: _secondaryEmail,
        password: _secondaryPassword,
      );

      final primarySync = HybridSyncService(
        client: primaryClient,
        cacheRepository: HybridCacheRepository(primaryDb),
      );
      final secondarySync = HybridSyncService(
        client: secondaryClient,
        cacheRepository: HybridCacheRepository(secondaryDb),
      );
      await primarySync.initializeHybridCacheIfNeeded();
      await secondarySync.initializeHybridCacheIfNeeded();

      final primaryProducts = _products(primaryClient, primaryDb, primarySync);
      final primaryCustomers =
          _customers(primaryClient, primaryDb, primarySync);
      final primaryInvoices = _invoices(primaryClient, primaryDb, primarySync);
      final secondaryInvoices =
          _invoices(secondaryClient, secondaryDb, secondarySync);

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final product = await primaryProducts.createProduct(
        CreateProductInput(
          companyName: 'Codex Sync Test',
          category: 'Validation',
          itemName: 'Two client item $suffix',
          itemNumber: 'SYNC-$suffix',
          buyingPrice: 8,
          sellingPrice: 10,
          gstRate: 0,
          quantityOnHand: 5,
          lowStockThreshold: 0,
        ),
      );
      created.productId = product.id;

      final customer = await primaryCustomers.createCustomer(
        CreateCustomerInput(
          name: 'Two client customer $suffix',
          address: 'Remote sync validation',
        ),
      );
      created.customerId = customer.id;

      final result = await primaryInvoices.createInvoice(
        draft: InvoiceDraft(
          customer: customer,
          invoiceDate: _today(),
          gstFlag: false,
          items: <InvoiceDraftItem>[
            InvoiceDraftItem(
              product: product,
              quantity: 1,
              unitPrice: 10,
              gstRate: 0,
            ),
          ],
        ),
        requestId: generateRequestId(),
      );
      created.invoiceId = result.invoice.id;
      expect(result.invoice.status, 'ACTIVE');
      expect(await _quantity(primaryDb, product.id), 4);

      await secondarySync.syncAll();
      final secondaryCopy =
          await secondaryInvoices.fetchInvoiceDetail(result.invoice.id);
      expect(secondaryCopy.invoiceNumber, result.invoice.invoiceNumber);
      expect(secondaryCopy.status, 'ACTIVE');
      expect(await _quantity(secondaryDb, product.id), 4);
      expect(
        await _transactionCount(secondaryDb, result.invoice.id),
        greaterThan(0),
      );

      final canceled = await secondaryInvoices.cancelInvoice(
        invoiceId: result.invoice.id,
        reason: 'Automated two-client validation',
      );
      expect(canceled.status, 'CANCELED');
      expect(await _quantity(secondaryDb, product.id), 5);

      await primarySync.syncAll();
      final primaryCanceled =
          await primaryInvoices.fetchInvoiceDetail(result.invoice.id);
      expect(primaryCanceled.status, 'CANCELED');
      expect(await _quantity(primaryDb, product.id), 5);
      expect(
        await _transactionCount(primaryDb, result.invoice.id),
        greaterThanOrEqualTo(2),
      );

      final remoteInvoice = await primaryClient
          .from('invoices')
          .select('status, invoice_number')
          .eq('id', result.invoice.id)
          .single();
      expect(remoteInvoice['status'], 'CANCELED');
      expect(
          '${remoteInvoice['invoice_number']}', result.invoice.invoiceNumber);
    } finally {
      await _cleanup(adminClient, created);
      await primaryDb.close();
      await secondaryDb.close();
      await primaryClient.dispose();
      await secondaryClient.dispose();
      await adminClient.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}

SupabaseClient _client(String key) {
  return SupabaseClient(
    _url,
    key,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

HybridProductsService _products(
  SupabaseClient client,
  LocalDatabase database,
  HybridSyncService sync,
) {
  return HybridProductsService(
    localProductsService: LocalProductsService(database: database),
    rpcClient: HybridRpcClient(client: client),
    refreshAfterWrite: sync.applyRpcResult,
  );
}

HybridCustomersService _customers(
  SupabaseClient client,
  LocalDatabase database,
  HybridSyncService sync,
) {
  return HybridCustomersService(
    localCustomersService: LocalCustomersService(database: database),
    rpcClient: HybridRpcClient(client: client),
    refreshAfterWrite: sync.applyRpcResult,
  );
}

HybridInvoicesService _invoices(
  SupabaseClient client,
  LocalDatabase database,
  HybridSyncService sync,
) {
  return HybridInvoicesService(
    localInvoicesService: LocalInvoicesService(database: database),
    rpcClient: HybridRpcClient(client: client),
    refreshAfterWrite: sync.applyRpcResult,
  );
}

Future<double> _quantity(LocalDatabase database, String productId) async {
  final row = await (database.select(database.products)
        ..where((product) => product.id.equals(productId)))
      .getSingle();
  return double.parse(row.quantityOnHand);
}

Future<int> _transactionCount(LocalDatabase database, String invoiceId) async {
  final rows = await (database.select(database.customerTransactions)
        ..where((transaction) => transaction.invoiceId.equals(invoiceId)))
      .get();
  return rows.length;
}

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

void _requireConfiguration() {
  final missing = <String, String>{
    'SUPABASE_URL': _url,
    'SUPABASE_ANON_KEY': _anonKey,
    'SUPABASE_SERVICE_ROLE_KEY': _serviceRoleKey,
    'PRIMARY_EMAIL': _primaryEmail,
    'PRIMARY_PASSWORD': _primaryPassword,
    'SECONDARY_EMAIL': _secondaryEmail,
    'SECONDARY_PASSWORD': _secondaryPassword,
  }.entries.where((entry) => entry.value.isEmpty).map((entry) => entry.key);
  if (missing.isNotEmpty) {
    fail('Missing live-test dart defines: ${missing.join(', ')}');
  }
}

Future<void> _cleanup(SupabaseClient admin, _CreatedRows rows) async {
  final invoiceIds = <String>{
    if (rows.invoiceId case final invoiceId?) invoiceId,
  };
  if (rows.customerId case final customerId?) {
    final remoteInvoices = await admin
        .from('invoices')
        .select('id')
        .eq('customer_id', customerId);
    invoiceIds.addAll(
      remoteInvoices.map((row) => row['id'] as String),
    );
  }
  for (final invoiceId in invoiceIds) {
    await admin
        .from('customer_transactions')
        .delete()
        .eq('invoice_id', invoiceId);
    await admin.from('stock_movements').delete().eq('invoice_id', invoiceId);
    await admin.from('invoice_items').delete().eq('invoice_id', invoiceId);
    await admin.from('invoices').delete().eq('id', invoiceId);
  }
  if (rows.productId case final productId?) {
    await admin.from('stock_movements').delete().eq('product_id', productId);
    await admin.from('products').delete().eq('id', productId);
  }
  if (rows.customerId case final customerId?) {
    await admin
        .from('customer_transactions')
        .delete()
        .eq('customer_id', customerId);
    await admin.from('customers').delete().eq('id', customerId);
  }
}

class _CreatedRows {
  String? productId;
  String? customerId;
  String? invoiceId;
}
