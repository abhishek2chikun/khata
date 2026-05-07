import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/local/local_auth_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';

void main() {
  late LocalDatabase database;
  late LocalAuthService service;

  setUp(() {
    database = LocalDatabase.memory();
    service = LocalAuthService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates first user and stores local password credentials', () async {
    final user = await service.createFirstUser(
      username: 'owner',
      password: 'correct horse battery staple',
      displayName: 'Owner',
    );

    expect(user.username, 'owner');
    expect(user.displayName, 'Owner');

    final storedUser = await database.select(database.localUsers).getSingle();
    expect(storedUser.id, user.id);
    expect(storedUser.salt, isNotEmpty);
    expect(storedUser.passwordHash, isNot('correct horse battery staple'));
    expect(storedUser.passwordHash, isNotEmpty);
    expect(storedUser.passwordHashVersion, 1);
  });

  test('rejects duplicate first user username', () async {
    await service.createFirstUser(username: 'owner', password: 'password-one');

    expect(
      () =>
          service.createFirstUser(username: 'owner', password: 'password-two'),
      throwsA(isA<AuthException>()),
    );
  });

  test('logs in successfully and returns current user from access token',
      () async {
    final createdUser = await service.createFirstUser(
      username: 'owner',
      password: 'correct horse battery staple',
      displayName: 'Owner',
    );

    final tokens = await service.login(
      username: 'owner',
      password: 'correct horse battery staple',
    );
    final currentUser = await service.me(accessToken: tokens.accessToken);

    expect(tokens.tokenType, 'bearer');
    expect(tokens.accessToken, isNotEmpty);
    expect(tokens.refreshToken, isNotEmpty);
    expect(currentUser.id, createdUser.id);
    expect(currentUser.username, 'owner');
    expect(currentUser.displayName, 'Owner');
  });

  test('rejects wrong password with invalid credentials error', () async {
    await service.createFirstUser(
      username: 'owner',
      password: 'correct horse battery staple',
    );

    expect(
      () => service.login(username: 'owner', password: 'wrong-password'),
      throwsA(
        isA<AuthException>()
            .having((error) => error.message, 'message',
                'Invalid username or password')
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.code, 'code', 'INVALID_CREDENTIALS'),
      ),
    );
  });

  test('returns me from refreshed local session token', () async {
    await service.createFirstUser(username: 'owner', password: 'password');
    final tokens = await service.login(username: 'owner', password: 'password');

    final refreshedTokens =
        await service.refresh(refreshToken: tokens.refreshToken);
    final currentUser =
        await service.me(accessToken: refreshedTokens.accessToken);

    expect(currentUser.username, 'owner');
  });

  test('clears local session on logout', () async {
    await service.createFirstUser(username: 'owner', password: 'password');
    final tokens = await service.login(username: 'owner', password: 'password');

    await service.logout(refreshToken: tokens.refreshToken);

    expect(await database.select(database.localSessions).get(), isEmpty);
    await expectLater(
      () => service.me(accessToken: tokens.accessToken),
      throwsA(isA<AuthException>()),
    );
  });
}
