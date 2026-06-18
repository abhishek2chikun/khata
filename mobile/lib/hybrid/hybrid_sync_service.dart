import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/local_database.dart';

class HybridCacheRepository {
  HybridCacheRepository(this._database);

  final LocalDatabase _database;

  static const hybridSettingsId = 'hybrid-cache';

  Future<bool> isHybridInitialized() async {
    final row = await (_database.select(_database.hybridCacheSettings)
          ..where((settings) => settings.id.equals(hybridSettingsId)))
        .getSingleOrNull();
    return row?.initialized ?? false;
  }

  Future<void> markHybridInitialized({String? lastSyncedAt}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.into(_database.hybridCacheSettings).insertOnConflictUpdate(
          HybridCacheSettingsCompanion.insert(
            id: hybridSettingsId,
            initialized: const Value(true),
            lastSyncedAt: Value(lastSyncedAt ?? now),
            updatedAt: now,
          ),
        );
  }

  Future<void> updateLastSyncedAt(String timestamp) async {
    await (_database.update(_database.hybridCacheSettings)
          ..where((settings) => settings.id.equals(hybridSettingsId)))
        .write(
      HybridCacheSettingsCompanion(
        lastSyncedAt: Value(timestamp),
        updatedAt: Value(timestamp),
      ),
    );
  }

  Future<void> clearBusinessCache() async {
    await _database.customStatement('PRAGMA foreign_keys = OFF');
    await _database.customStatement('DELETE FROM invoice_items');
    await _database.customStatement('DELETE FROM stock_movements');
    await _database.customStatement('DELETE FROM customer_transactions');
    await _database.customStatement('DELETE FROM buyer_transactions');
    await _database.customStatement('DELETE FROM invoices');
    await _database.customStatement('DELETE FROM products');
    await _database.customStatement('DELETE FROM customers');
    await _database.customStatement('DELETE FROM buyers');
    await _database.customStatement('DELETE FROM company_profiles');
    await _database.customStatement('PRAGMA foreign_keys = ON');
  }

  Future<void> upsertProduct(Map<String, dynamic> row) async {
    await _database.into(_database.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: row['id'] as String,
            itemNumber: row['item_number'] as String,
            itemName: row['item_name'] as String,
            category: row['category'] as String,
            buyerId: Value(row['buyer_id'] as String?),
            companyName: row['company_name'] as String,
            buyingPrice: '${row['buying_price']}',
            sellingPrice: '${row['selling_price']}',
            unit: Value(row['unit'] as String?),
            gstRate: '${row['gst_rate']}',
            hsnCode: Value(row['hsn_code'] as String?),
            quantityOnHand: '${row['quantity_on_hand']}',
            lowStockThreshold: '${row['low_stock_threshold'] ?? '0'}',
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: _asIso(row['created_at']),
            updatedAt: _asIso(row['updated_at']),
          ),
        );
  }

  Future<void> upsertBuyer(Map<String, dynamic> row) async {
    await _database.into(_database.buyers).insertOnConflictUpdate(
          BuyersCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            address: row['address'] as String? ?? '',
            state: Value(row['state'] as String?),
            stateCode: Value(row['state_code'] as String?),
            phone: Value(row['phone'] as String?),
            gstin: Value(row['gstin'] as String?),
            whatsappNumber: Value(row['whatsapp_number'] as String?),
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: _asIso(row['created_at']),
            updatedAt: _asIso(row['updated_at']),
          ),
        );
  }

  Future<void> upsertCustomer(Map<String, dynamic> row) async {
    await _database.into(_database.customers).insertOnConflictUpdate(
          CustomersCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            address: row['address'] as String,
            state: Value(row['state'] as String?),
            stateCode: Value(row['state_code'] as String?),
            phone: Value(row['phone'] as String?),
            gstin: Value(row['gstin'] as String?),
            whatsappNumber: Value(row['whatsapp_number'] as String?),
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: _asIso(row['created_at']),
            updatedAt: _asIso(row['updated_at']),
          ),
        );
  }

  Future<void> upsertCompanyProfile(Map<String, dynamic> row) async {
    await _database.into(_database.companyProfiles).insertOnConflictUpdate(
          CompanyProfilesCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            address: row['address'] as String,
            city: row['city'] as String,
            state: row['state'] as String,
            stateCode: row['state_code'] as String,
            gstin: Value(row['gstin'] as String?),
            gstFlag: Value((row['gst_flag'] as bool?) ?? false),
            phone: Value(row['phone'] as String?),
            email: Value(row['email'] as String?),
            bankName: Value(row['bank_name'] as String?),
            bankAccount: Value(row['bank_account'] as String?),
            bankIfsc: Value(row['bank_ifsc'] as String?),
            bankBranch: Value(row['bank_branch'] as String?),
            jurisdiction: Value(row['jurisdiction'] as String?),
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: _asIso(row['created_at']),
            updatedAt: _asIso(row['updated_at']),
          ),
        );
  }

  Future<void> upsertInvoice(Map<String, dynamic> row) async {
    final userId = row['created_by_user_id'] as String;
    await ensureOperatorUser(
      userId: userId,
      username: userId,
      displayName: userId,
    );
    await _database.into(_database.invoices).insertOnConflictUpdate(
          InvoicesCompanion.insert(
            id: row['id'] as String,
            requestId: row['request_id'] as String,
            requestHash: row['request_hash'] as String,
            invoiceNumber: (row['invoice_number'] as num).toInt(),
            customerId: row['customer_id'] as String,
            customerName: row['customer_name'] as String,
            customerAddress: row['customer_address'] as String,
            customerState: Value(row['customer_state'] as String?),
            customerStateCode: Value(row['customer_state_code'] as String?),
            customerPhone: Value(row['customer_phone'] as String?),
            customerWhatsappNumber:
                Value(row['customer_whatsapp_number'] as String?),
            customerGstin: Value(row['customer_gstin'] as String?),
            placeOfSupplyState: row['place_of_supply_state'] as String,
            placeOfSupplyStateCode: row['place_of_supply_state_code'] as String,
            companyName: row['company_name'] as String,
            companyAddress: row['company_address'] as String,
            companyCity: row['company_city'] as String,
            companyState: row['company_state'] as String,
            companyStateCode: row['company_state_code'] as String,
            companyGstin: Value(row['company_gstin'] as String?),
            companyPhone: Value(row['company_phone'] as String?),
            companyEmail: Value(row['company_email'] as String?),
            companyBankName: Value(row['company_bank_name'] as String?),
            companyBankAccount: Value(row['company_bank_account'] as String?),
            companyBankIfsc: Value(row['company_bank_ifsc'] as String?),
            companyBankBranch: Value(row['company_bank_branch'] as String?),
            companyJurisdiction: Value(row['company_jurisdiction'] as String?),
            gstFlag: Value((row['gst_flag'] as bool?) ?? false),
            invoiceDate: (row['invoice_date'] as String).substring(0, 10),
            invoiceDatetime: Value(row['invoice_datetime'] as String? ??
                row['created_at'] as String? ??
                _asIso(null)),
            taxRegime: row['tax_regime'] as String,
            status: row['status'] as String,
            paymentState: Value(row['payment_state'] as String),
            paidAmount: Value('${row['paid_amount']}'),
            paymentMode: row['payment_state'] as String,
            subtotal: '${row['subtotal']}',
            discountTotal: '${row['discount_total']}',
            taxableTotal: '${row['taxable_total']}',
            gstTotal: '${row['gst_total']}',
            grandTotal: '${row['grand_total']}',
            notes: Value(row['notes'] as String?),
            createdByUserId: row['created_by_user_id'] as String,
            cancelRequestId: Value(row['cancel_request_id'] as String?),
            cancelRequestHash: Value(row['cancel_request_hash'] as String?),
            canceledByUserId: Value(row['canceled_by_user_id'] as String?),
            cancelReason: Value(row['cancel_reason'] as String?),
            canceledAt: Value(row['canceled_at'] as String?),
            createdAt: _asIso(row['created_at']),
          ),
        );
  }

  Future<void> upsertInvoiceItem(Map<String, dynamic> row) async {
    await _database.into(_database.invoiceItems).insertOnConflictUpdate(
          InvoiceItemsCompanion.insert(
            id: row['id'] as String,
            invoiceId: row['invoice_id'] as String,
            productId: row['product_id'] as String,
            lineNumber: (row['line_number'] as num).toInt(),
            productName: row['product_name'] as String? ??
                row['product_item_name'] as String,
            productCode: row['product_code'] as String? ??
                row['product_item_number'] as String,
            productItemNumber:
                Value(row['product_item_number'] as String? ?? ''),
            productItemName: Value(row['product_item_name'] as String? ?? ''),
            productCategory: Value(row['product_category'] as String? ?? ''),
            productBuyerId: Value(row['product_buyer_id'] as String?),
            productCompanyName:
                Value(row['product_company_name'] as String? ?? ''),
            productHsnCode: Value(row['product_hsn_code'] as String?),
            buyingPrice: Value('${row['buying_price']}'),
            sellingPrice: Value('${row['selling_price']}'),
            unit: Value(row['unit'] as String?),
            company: row['company'] as String? ??
                row['product_company_name'] as String? ??
                '',
            category: row['category'] as String? ??
                row['product_category'] as String? ??
                '',
            quantity: '${row['quantity']}',
            pricingMode: row['pricing_mode'] as String,
            enteredUnitPrice: '${row['entered_unit_price']}',
            unitPriceExclTax: '${row['unit_price_excl_tax']}',
            unitPriceInclTax: '${row['unit_price_incl_tax']}',
            gstRate: '${row['gst_rate']}',
            cgstRate: '${row['cgst_rate']}',
            sgstRate: '${row['sgst_rate']}',
            igstRate: '${row['igst_rate']}',
            discountPercent: '${row['discount_percent']}',
            discountAmount: '${row['discount_amount']}',
            taxableAmount: '${row['taxable_amount']}',
            gstAmount: '${row['gst_amount']}',
            cgstAmount: '${row['cgst_amount']}',
            sgstAmount: '${row['sgst_amount']}',
            igstAmount: '${row['igst_amount']}',
            lineTotal: '${row['line_total']}',
            revenueAmount: Value('${row['revenue_amount']}'),
            buyingAmount: Value('${row['buying_amount']}'),
            profitAmount: Value('${row['profit_amount']}'),
          ),
        );
  }

  Future<void> upsertStockMovement(Map<String, dynamic> row) async {
    await ensureOperatorUser(
      userId: row['created_by_user_id'] as String,
      username: row['created_by_user_id'] as String,
      displayName: row['created_by_user_id'] as String,
    );
    await _database.into(_database.stockMovements).insertOnConflictUpdate(
          StockMovementsCompanion.insert(
            id: row['id'] as String,
            productId: row['product_id'] as String,
            invoiceId: Value(row['invoice_id'] as String?),
            requestId: Value(row['request_id'] as String?),
            requestHash: Value(row['request_hash'] as String?),
            movementType: row['movement_type'] as String,
            quantityDelta: '${row['quantity_delta']}',
            reason: Value(row['reason'] as String?),
            createdByUserId: row['created_by_user_id'] as String,
            createdAt: _asIso(row['created_at']),
          ),
        );
  }

  Future<void> upsertCustomerTransaction(Map<String, dynamic> row) async {
    await ensureOperatorUser(
      userId: row['created_by_user_id'] as String,
      username: row['created_by_user_id'] as String,
      displayName: row['created_by_user_id'] as String,
    );
    await _database.into(_database.customerTransactions).insertOnConflictUpdate(
          CustomerTransactionsCompanion.insert(
            id: row['id'] as String,
            customerId: row['customer_id'] as String,
            invoiceId: Value(row['invoice_id'] as String?),
            requestId: Value(row['request_id'] as String?),
            requestHash: Value(row['request_hash'] as String?),
            openingBalanceCustomerId:
                Value(row['opening_balance_customer_id'] as String?),
            entryType: row['entry_type'] as String,
            amount: '${row['amount']}',
            occurredOn: (row['occurred_on'] as String).substring(0, 10),
            notes: Value(row['notes'] as String?),
            createdByUserId: row['created_by_user_id'] as String,
            createdAt: _asIso(row['created_at']),
          ),
        );
  }

  Future<void> upsertBuyerTransaction(Map<String, dynamic> row) async {
    await ensureOperatorUser(
      userId: row['created_by_user_id'] as String,
      username: row['created_by_user_id'] as String,
      displayName: row['created_by_user_id'] as String,
    );
    final entryType = row['entry_type'] as String;
    await _database.into(_database.buyerTransactions).insertOnConflictUpdate(
          BuyerTransactionsCompanion.insert(
            id: row['id'] as String,
            buyerId: row['buyer_id'] as String,
            requestId: Value(row['request_id'] as String?),
            requestHash: Value(row['request_hash'] as String?),
            openingPayableBuyerId: Value(
              entryType == 'OPENING_PAYABLE' ? row['buyer_id'] as String : null,
            ),
            entryType: entryType,
            amount: '${row['amount']}',
            occurredAt: _asIso(row['occurred_at']),
            notes: Value(row['notes'] as String?),
            createdByUserId: row['created_by_user_id'] as String,
            createdAt: _asIso(row['created_at']),
          ),
        );
  }

  String _asIso(dynamic value) {
    if (value == null) {
      return DateTime.now().toUtc().toIso8601String();
    }
    return value.toString();
  }

  Future<void> ensureOperatorUser({
    required String userId,
    required String username,
    String? displayName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.into(_database.localUsers).insertOnConflictUpdate(
          LocalUsersCompanion.insert(
            id: userId,
            username: username,
            passwordHash: 'supabase-auth',
            displayName: Value(displayName),
            salt: 'hybrid',
            passwordHashVersion: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
}

class HybridSyncService {
  HybridSyncService({
    required SupabaseClient client,
    required HybridCacheRepository cacheRepository,
  })  : _client = client,
        _cacheRepository = cacheRepository;

  final SupabaseClient _client;
  final HybridCacheRepository _cacheRepository;

  bool _isSyncing = false;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  Future<void> initializeHybridCacheIfNeeded() async {
    if (await _cacheRepository.isHybridInitialized()) {
      return;
    }
    await _cacheRepository.clearBusinessCache();
    await syncAll(forceFull: true);
    await _cacheRepository.markHybridInitialized();
  }

  Future<void> syncAll({bool forceFull = false}) async {
    if (_client.auth.currentSession == null) {
      _lastError = 'Sign in required before sync';
      return;
    }

    _isSyncing = true;
    _lastError = null;
    try {
      await _syncTable('buyers', _cacheRepository.upsertBuyer);
      await _syncTable('customers', _cacheRepository.upsertCustomer);
      await _syncTable('products', _cacheRepository.upsertProduct);
      await _syncTable(
          'company_profiles', _cacheRepository.upsertCompanyProfile);
      await _syncTable('invoices', _cacheRepository.upsertInvoice);
      await _syncInvoiceItems();
      await _syncTable('stock_movements', _cacheRepository.upsertStockMovement);
      await _syncTable(
        'customer_transactions',
        _cacheRepository.upsertCustomerTransaction,
      );
      await _syncTable(
        'buyer_transactions',
        _cacheRepository.upsertBuyerTransaction,
      );
      final now = DateTime.now().toUtc().toIso8601String();
      await _cacheRepository.updateLastSyncedAt(now);
    } on Object catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTable(
    String table,
    Future<void> Function(Map<String, dynamic>) upsert,
  ) async {
    final rows = await _client.from(table).select();
    for (final row in rows) {
      await upsert(Map<String, dynamic>.from(row as Map));
    }
  }

  Future<void> _syncInvoiceItems() async {
    final rows = await _client.from('invoice_items').select();
    for (final row in rows) {
      await _cacheRepository
          .upsertInvoiceItem(Map<String, dynamic>.from(row as Map));
    }
  }
}
