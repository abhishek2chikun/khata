import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';

void main() {
  late Map<String, String> storageData;

  setUp(() {
    storageData = <String, String>{};
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(storageData);
  });

  test('default store preserves existing unscoped API session keys', () async {
    final store = SecureSessionStore(storage: const FlutterSecureStorage());

    await store.writeSession(
      const StoredSession(
        accessToken: 'api-access',
        refreshToken: 'api-refresh',
        tokenType: 'Bearer',
      ),
    );

    expect(storageData['auth.access_token'], 'api-access');
    expect(storageData['auth.refresh_token'], 'api-refresh');
    expect(storageData['auth.token_type'], 'Bearer');
  });

  test('prefixed stores do not read or clear default API session keys',
      () async {
    final apiStore = SecureSessionStore(storage: const FlutterSecureStorage());
    final localStore = SecureSessionStore(
      storage: const FlutterSecureStorage(),
      keyPrefix: 'auth.local',
    );
    await apiStore.writeSession(
      const StoredSession(
        accessToken: 'api-access',
        refreshToken: 'api-refresh',
        tokenType: 'Bearer',
      ),
    );
    await localStore.writeSession(
      const StoredSession(
        accessToken: 'local-access',
        refreshToken: 'local-refresh',
        tokenType: 'Bearer',
      ),
    );

    expect((await apiStore.readSession())!.accessToken, 'api-access');
    expect((await localStore.readSession())!.accessToken, 'local-access');

    await localStore.clearSession();

    expect((await apiStore.readSession())!.accessToken, 'api-access');
    expect(await localStore.readSession(), isNull);
  });
}
