import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/local_database.dart';
import '../debug/agent_debug_log.dart';

Future<int> syncPaginatedTable({
  required Future<List<Map<String, dynamic>>> Function(int from, int to)
      fetchPage,
  required int pageSize,
  required Future<void> Function(Map<String, dynamic>) upsert,
}) async {
  var from = 0;
  var total = 0;
  while (true) {
    final to = from + pageSize - 1;
    final rows = await fetchPage(from, to);
    if (rows.isEmpty) {
      break;
    }
    for (final row in rows) {
      await upsert(row);
      total++;
    }
    if (rows.length < pageSize) {
      break;
    }
    from += pageSize;
  }
  return total;
}

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

  Future<int> countActiveProducts() async {
    final countExpr = _database.products.id.count();
    final query = _database.selectOnly(_database.products)
      ..addColumns([countExpr])
      ..where(_database.products.isActive.equals(true));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<void> deactivateProductsNotIn(Set<String> activeIds) async {
    if (activeIds.isEmpty) {
      return;
    }
    await (_database.update(_database.products)
          ..where(
            (product) =>
                product.isActive.equals(true) & product.id.isNotIn(activeIds),
          ))
        .write(
      const ProductsCompanion(
        isActive: Value(false),
      ),
    );
  }

  Future<void> upsertProduct(Map<String, dynamic> row) async {
    await _database.into(_database.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: row['id'] as String,
            itemNumber: row['item_number'] as String,
            itemName: row['item_name'] as String,
            category: row['category'] as String,
            buyerId: Value(row['buyer_id']?.toString()),
            companyName: row['company_name'] as String,
            buyingPrice: '${row['buying_price']}',
            sellingPrice: '${row['selling_price']}',
            unit: Value(row['unit'] as String?),
            gstRate: '${row['gst_rate']}',
            hsnCode: Value(row['hsn_code']?.toString()),
            quantityOnHand: '${row['quantity_on_hand']}',
            lowStockThreshold: '${row['low_stock_threshold'] ?? '0'}',
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: _asIso(row['created_at']),
            updatedAt: _asIso(row['updated_at']),
          ),
        );
  }

  /// Applies a remote product row only when it is newer than the local cache.
  /// RPC hydration uses [upsertProduct] instead because the server response is
  /// authoritative for writes initiated on this device.
  Future<void> upsertProductIfNewer(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final incomingUpdatedAt = DateTime.parse(_asIso(row['updated_at']));
    final existing = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingleOrNull();
    if (existing != null) {
      final localUpdatedAt = DateTime.parse(existing.updatedAt);
      if (!incomingUpdatedAt.isAfter(localUpdatedAt)) {
        return;
      }
    }
    await upsertProduct(row);
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
  bool _syncPending = false;
  final Set<String> _rpcTouchedProductIds = <String>{};
  String? _lastError;
  Map<String, int>? _lastSyncedCounts;
  Timer? _backgroundSyncTimer;
  Timer? _periodicSyncTimer;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  Map<String, int>? get lastSyncedCounts => _lastSyncedCounts;

  void scheduleBackgroundSync({
    Duration delay = const Duration(seconds: 2),
  }) {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer(delay, () {
      unawaited(
        syncAll().catchError((Object error) {
          _lastError = error.toString();
        }),
      );
    });
  }

  void startPeriodicBackgroundSync({
    Duration interval = const Duration(minutes: 10),
  }) {
    if (_periodicSyncTimer != null) {
      return;
    }
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      scheduleBackgroundSync(delay: Duration.zero);
    });
  }

  void stopPeriodicBackgroundSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  void dispose() {
    _backgroundSyncTimer?.cancel();
    _periodicSyncTimer?.cancel();
  }

  void _trackRpcProduct(Object? row) {
    if (row is! Map) {
      return;
    }
    final id = row['id'];
    if (id is String && id.isNotEmpty) {
      _rpcTouchedProductIds.add(id);
    }
  }

  Future<void> applyRpcResult(
    String functionName,
    Map<String, dynamic> result,
  ) async {
    switch (functionName) {
      case 'create_product':
      case 'update_product':
      case 'archive_product':
      case 'reactivate_product':
        _trackRpcProduct(result);
        await _cacheRepository.upsertProduct(result);
        break;
      case 'adjust_stock':
        await _upsertObject(
          result['stock_movement'],
          _cacheRepository.upsertStockMovement,
        );
        _trackRpcProduct(result['product']);
        await _upsertObject(result['product'], _cacheRepository.upsertProduct);
        break;
      case 'create_customer':
      case 'update_customer':
        await _cacheRepository.upsertCustomer(result);
        break;
      case 'create_buyer':
      case 'update_buyer':
      case 'archive_buyer':
      case 'reactivate_buyer':
        await _cacheRepository.upsertBuyer(result);
        break;
      case 'upsert_company_profile':
        await _cacheRepository.upsertCompanyProfile(result);
        break;
      case 'record_collection':
      case 'record_customer_ledger_entry':
        await _cacheRepository.upsertCustomerTransaction(result);
        break;
      case 'record_buyer_ledger_entry':
        await _cacheRepository.upsertBuyerTransaction(result);
        break;
      case 'create_invoice':
      case 'cancel_invoice':
        for (final row in (result['products'] as Iterable?) ?? const []) {
          _trackRpcProduct(row);
        }
        await _upsertRows(result['products'], _cacheRepository.upsertProduct);
        await _upsertObject(result['invoice'], _cacheRepository.upsertInvoice);
        await _upsertRows(result['items'], _cacheRepository.upsertInvoiceItem);
        await _upsertRows(
          result['stock_movements'],
          _cacheRepository.upsertStockMovement,
        );
        await _upsertRows(
          result['customer_transactions'],
          _cacheRepository.upsertCustomerTransaction,
        );
        break;
      case 'record_batch_collections':
        await _hydrateBatchCollections(result);
        break;
    }
  }

  Future<void> _hydrateBatchCollections(Map<String, dynamic> result) async {
    final requestId = result['request_id'] as String?;
    if (requestId == null || _client.auth.currentSession == null) {
      return;
    }
    final rows = await _client
        .from('customer_transactions')
        .select()
        .like('notes', batchCollectionNotesFilter(requestId));
    await _upsertRows(rows, _cacheRepository.upsertCustomerTransaction);
  }

  Future<void> initializeHybridCacheIfNeeded() async {
    if (await _cacheRepository.isHybridInitialized()) {
      // #region agent log
      AgentDebugLog.write(
        location: 'hybrid_sync_service.dart:initializeHybridCacheIfNeeded',
        message: 'hybrid cache already initialized',
        hypothesisId: 'H-sync',
        data: {'skipped': true},
      );
      // #endregion
      await _recoverStaleProductCatalogIfNeeded();
      return;
    }
    // #region agent log
    AgentDebugLog.write(
      location: 'hybrid_sync_service.dart:initializeHybridCacheIfNeeded',
      message: 'clearing local business cache before first sync',
      hypothesisId: 'H-sync',
    );
    // #endregion
    await _cacheRepository.clearBusinessCache();
    await syncAll(forceFull: true);
    await _cacheRepository.markHybridInitialized();
    // #region agent log
    AgentDebugLog.write(
      location: 'hybrid_sync_service.dart:initializeHybridCacheIfNeeded',
      message: 'hybrid cache initialized',
      hypothesisId: 'H-sync',
      data: {'lastError': _lastError},
    );
    // #endregion
  }

  // Supabase projects commonly cap REST responses at 1,000 rows even when the
  // requested range is larger. Keep the client page at that cap so a short page
  // remains a reliable end-of-table signal.
  static const _syncPageSize = 1000;

  /// Returns true when a sync pass actually ran; false when skipped because
  /// another sync was already in flight (a follow-up pass is scheduled).
  Future<bool> syncAll({bool forceFull = false}) async {
    if (_isSyncing) {
      _syncPending = true;
      return false;
    }
    if (_client.auth.currentSession == null) {
      _lastError = 'Sign in required before sync';
      // #region agent log
      AgentDebugLog.write(
        location: 'hybrid_sync_service.dart:syncAll',
        message: 'sync skipped without session',
        hypothesisId: 'H-session',
      );
      // #endregion
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    _lastSyncedCounts = null;
    _rpcTouchedProductIds.clear();
    final syncedCounts = <String, int>{};
    try {
      syncedCounts['buyers'] =
          await _syncTable('buyers', _cacheRepository.upsertBuyer);
      syncedCounts['customers'] =
          await _syncTable('customers', _cacheRepository.upsertCustomer);
      syncedCounts['products'] = await _syncActiveProducts();
      syncedCounts['company_profiles'] = await _syncTable(
        'company_profiles',
        _cacheRepository.upsertCompanyProfile,
      );
      syncedCounts['invoices'] =
          await _syncTable('invoices', _cacheRepository.upsertInvoice);
      syncedCounts['invoice_items'] = await _syncInvoiceItems();
      syncedCounts['stock_movements'] = await _syncTable(
        'stock_movements',
        _cacheRepository.upsertStockMovement,
      );
      syncedCounts['customer_transactions'] = await _syncTable(
        'customer_transactions',
        _cacheRepository.upsertCustomerTransaction,
      );
      syncedCounts['buyer_transactions'] = await _syncTable(
        'buyer_transactions',
        _cacheRepository.upsertBuyerTransaction,
      );
      await _ensureProductCatalogComplete(syncedCounts);
      _lastSyncedCounts = Map<String, int>.from(syncedCounts);
      final now = DateTime.now().toUtc().toIso8601String();
      await _cacheRepository.updateLastSyncedAt(now);
      // #region agent log
      AgentDebugLog.write(
        location: 'hybrid_sync_service.dart:syncAll',
        message: 'sync complete',
        hypothesisId: 'H-sync',
        data: syncedCounts,
        runId: 'post-fix',
      );
      // #endregion
    } on Object catch (error) {
      _lastError = error.toString();
      // #region agent log
      AgentDebugLog.write(
        location: 'hybrid_sync_service.dart:syncAll',
        message: 'sync failed',
        hypothesisId: 'H-sync',
        data: {'error': _lastError, 'syncedCounts': syncedCounts},
        runId: 'post-fix',
      );
      // #endregion
      rethrow;
    } finally {
      _isSyncing = false;
      final shouldRerun = _syncPending;
      _syncPending = false;
      if (shouldRerun) {
        unawaited(
          syncAll(forceFull: forceFull).catchError((Object error) {
            _lastError = error.toString();
          }),
        );
      }
    }
    return true;
  }

  Future<void> _upsertObject(
    Object? row,
    Future<void> Function(Map<String, dynamic>) upsert,
  ) async {
    if (row == null) {
      return;
    }
    await upsert(Map<String, dynamic>.from(row as Map));
  }

  Future<void> _upsertRows(
    Object? rows,
    Future<void> Function(Map<String, dynamic>) upsert,
  ) async {
    if (rows == null) {
      return;
    }
    for (final row in rows as Iterable) {
      await upsert(Map<String, dynamic>.from(row as Map));
    }
  }

  Future<int> _syncActiveProducts() async {
    final activeIds = <String>{};
    final total = await syncPaginatedTable(
      pageSize: _syncPageSize,
      fetchPage: (from, to) async {
        final rows = await _client
            .from('products')
            .select()
            .eq('is_active', true)
            .order('id')
            .range(from, to);
        return rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      },
      upsert: (row) async {
        activeIds.add(row['id'] as String);
        await _cacheRepository.upsertProductIfNewer(row);
      },
    );
    final protectedIds = <String>{...activeIds, ..._rpcTouchedProductIds};
    await _cacheRepository.deactivateProductsNotIn(protectedIds);
    return total;
  }

  Future<int> _syncTable(
    String table,
    Future<void> Function(Map<String, dynamic>) upsert, {
    bool activeOnly = false,
  }) async {
    return syncPaginatedTable(
      pageSize: _syncPageSize,
      fetchPage: (from, to) async {
        var query = _client.from(table).select();
        if (activeOnly) {
          query = query.eq('is_active', true);
        }
        final rows = await query.order('id').range(from, to);
        return rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      },
      upsert: upsert,
    );
  }

  Future<int> _syncInvoiceItems() async {
    return syncPaginatedTable(
      pageSize: _syncPageSize,
      fetchPage: (from, to) async {
        final rows = await _client
            .from('invoice_items')
            .select()
            .order('id')
            .range(from, to);
        return rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      },
      upsert: _cacheRepository.upsertInvoiceItem,
    );
  }

  Future<int?> _fetchRemoteProductCount() async {
    try {
      return await _client
          .from('products')
          .count(CountOption.exact)
          .eq('is_active', true);
    } on Object catch (error) {
      AgentDebugLog.write(
        location: 'hybrid_sync_service.dart:_fetchRemoteProductCount',
        message: 'remote product count failed',
        hypothesisId: 'H-sync',
        data: {'error': error.toString()},
      );
      return null;
    }
  }

  Future<void> _recoverStaleProductCatalogIfNeeded() async {
    if (_client.auth.currentSession == null) {
      return;
    }
    final localCount = await _cacheRepository.countActiveProducts();
    final remoteCount = await _fetchRemoteProductCount();
    if (remoteCount == null) {
      return;
    }
    if (localCount == 1000 && remoteCount > 1000) {
      await syncAll();
    }
  }

  Future<void> _ensureProductCatalogComplete(
    Map<String, int> syncedCounts,
  ) async {
    final remoteCount = await _fetchRemoteProductCount();
    if (remoteCount == null) {
      return;
    }
    var localCount = await _cacheRepository.countActiveProducts();
    if (localCount >= remoteCount) {
      return;
    }

    AgentDebugLog.write(
      location: 'hybrid_sync_service.dart:_ensureProductCatalogComplete',
      message: 'product catalog incomplete, re-syncing products',
      hypothesisId: 'H-sync',
      data: {'localCount': localCount, 'remoteCount': remoteCount},
    );

    syncedCounts['products'] = await _syncActiveProducts();
    localCount = await _cacheRepository.countActiveProducts();
    if (localCount < remoteCount) {
      _lastError =
          'Catalog sync incomplete: $localCount of $remoteCount products cached locally';
    }
  }
}

/// PostgREST `notes` filter for rows created by [record_batch_collections].
String batchCollectionNotesFilter(String requestId) =>
    '__batch__|$requestId|%';
