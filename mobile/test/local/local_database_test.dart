import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';

void main() {
  test('local database exposes schema version and core tables', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(database.schemaVersion, 1);
    expect(database.allTables.map((table) => table.actualTableName), containsAll(<String>[
      'local_users',
      'products',
      'stock_movements',
      'sellers',
      'seller_transactions',
      'company_profiles',
      'invoices',
      'invoice_items',
      'local_sessions',
      'backup_events',
      'backup_settings',
    ]));
  });
}
