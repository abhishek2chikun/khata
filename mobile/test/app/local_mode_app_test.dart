import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/main.dart';

void main() {
  testWidgets('local mode sets up first user and opens inventory',
      (tester) async {
    final database = LocalDatabase.memory();
    final dependencies = await AppDependencies.create(
      mode: DataMode.local,
      localDatabase: database,
      sessionStore: _MemorySessionStore(),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      BillingApp(
        dependencies: dependencies,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up local user'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Username'), 'owner');
    await tester.enterText(find.bySemanticsLabel('Display name'), 'Owner');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.tap(find.text('Create user'));
    await tester.pumpAndSettle();

    expect(
        find.text('Sign in with your username and password.'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Username'), 'owner');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
  });
}

class _MemorySessionStore implements SessionStore {
  StoredSession? _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<StoredSession?> readSession() async => _session;

  @override
  Future<void> writeSession(StoredSession session) async {
    _session = session;
  }
}
