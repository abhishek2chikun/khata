import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
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
    expect(await database.select(database.localUsers).get(), hasLength(1));
  });

  test('enforces unique local usernames at the database level', () async {
    await service.createFirstUser(username: 'owner', password: 'password-one');

    await expectLater(
      () => database.into(database.localUsers).insert(
            LocalUsersCompanion.insert(
              id: 'different-user-id',
              username: 'owner',
              passwordHash: 'hash',
              salt: 'salt',
              passwordHashVersion: 1,
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-01T00:00:00.000Z',
            ),
          ),
      throwsA(isA<Object>()),
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

  test('does not persist plaintext refresh token in local session fields',
      () async {
    await service.createFirstUser(username: 'owner', password: 'password');
    final tokens = await service.login(username: 'owner', password: 'password');

    final session = await database.select(database.localSessions).getSingle();

    expect(session.id, isNot(tokens.refreshToken));
    expect(session.sessionTokenHash, isNot(tokens.refreshToken));
  });

  test('refresh rotates refresh tokens and rejects the old refresh token',
      () async {
    await service.createFirstUser(username: 'owner', password: 'password');
    final tokens = await service.login(username: 'owner', password: 'password');

    final refreshedTokens =
        await service.refresh(refreshToken: tokens.refreshToken);

    expect(refreshedTokens.refreshToken, isNot(tokens.refreshToken));
    await expectLater(
      () => service.refresh(refreshToken: tokens.refreshToken),
      throwsA(isA<AuthException>()),
    );
    final secondRefresh =
        await service.refresh(refreshToken: refreshedTokens.refreshToken);
    expect(secondRefresh.refreshToken, isNot(refreshedTokens.refreshToken));
  });

  test('inactive users cannot login and existing tokens stop working',
      () async {
    await service.createFirstUser(username: 'owner', password: 'password');
    final tokens = await service.login(username: 'owner', password: 'password');

    await database.update(database.localUsers).write(
          const LocalUsersCompanion(isActive: Value(false)),
        );

    await expectLater(
      () => service.login(username: 'owner', password: 'password'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      () => service.me(accessToken: tokens.accessToken),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      () => service.refresh(refreshToken: tokens.refreshToken),
      throwsA(isA<AuthException>()),
    );
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
