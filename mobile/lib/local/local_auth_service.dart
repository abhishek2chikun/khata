import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../auth/auth_service.dart';
import 'local_database.dart';
import 'local_password_hasher.dart';

class LocalAuthService implements AuthService {
  LocalAuthService({
    required LocalDatabase database,
    LocalPasswordHasher? passwordHasher,
  })  : _database = database,
        _passwordHasher = passwordHasher ?? LocalPasswordHasher();

  final LocalDatabase _database;
  final LocalPasswordHasher _passwordHasher;

  Future<AuthUser> createFirstUser({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final existingUser = await (_database.select(_database.localUsers)
          ..where((user) => user.username.equals(username)))
        .getSingleOrNull();
    if (existingUser != null) {
      throw const AuthException('Username already exists', statusCode: 409);
    }

    final passwordHash = _passwordHasher.hashPassword(password);
    final now = DateTime.now().toUtc().toIso8601String();
    final userId = _generateToken();
    try {
      await _database.into(_database.localUsers).insert(
            LocalUsersCompanion.insert(
              id: userId,
              username: username,
              passwordHash: passwordHash.hash,
              displayName: Value(displayName),
              salt: passwordHash.salt,
              passwordHashVersion: passwordHash.version,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Object {
      final duplicateUser = await (_database.select(_database.localUsers)
            ..where((user) => user.username.equals(username)))
          .getSingleOrNull();
      if (duplicateUser != null) {
        throw const AuthException('Username already exists', statusCode: 409);
      }
      rethrow;
    }
    return AuthUser(id: userId, username: username, displayName: displayName);
  }

  @override
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  }) async {
    final user = await (_database.select(_database.localUsers)
          ..where((user) => user.username.equals(username)))
        .getSingleOrNull();
    if (user == null ||
        !user.isActive ||
        !_passwordHasher.verify(
          password: password,
          salt: user.salt,
          passwordHash: user.passwordHash,
          version: user.passwordHashVersion,
        )) {
      throw _invalidCredentials();
    }

    await (_database.delete(_database.localSessions)
          ..where((session) => session.localUserId.equals(user.id)))
        .go();

    final accessToken = _generateToken();
    final refreshToken = _generateToken();
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.into(_database.localSessions).insert(
          LocalSessionsCompanion.insert(
            id: _generateToken(),
            localUserId: user.id,
            sessionTokenHash: _passwordHasher.hashToken(accessToken),
            refreshTokenHash: _passwordHasher.hashToken(refreshToken),
            createdAt: now,
          ),
        );

    return AuthSessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: 'bearer',
    );
  }

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) async {
    final session = await (_database.select(_database.localSessions)
          ..where(
            (session) => session.refreshTokenHash.equals(
              _passwordHasher.hashToken(refreshToken),
            ),
          ))
        .getSingleOrNull();
    if (session == null) {
      throw _invalidCredentials();
    }

    final user = await (_database.select(_database.localUsers)
          ..where((user) => user.id.equals(session.localUserId)))
        .getSingleOrNull();
    if (user == null || !user.isActive) {
      throw _invalidCredentials();
    }

    final accessToken = _generateToken();
    final newRefreshToken = _generateToken();
    final now = DateTime.now().toUtc().toIso8601String();
    await (_database.delete(_database.localSessions)
          ..where((storedSession) => storedSession.id.equals(session.id)))
        .go();
    await _database.into(_database.localSessions).insert(
          LocalSessionsCompanion.insert(
            id: _generateToken(),
            localUserId: user.id,
            sessionTokenHash: _passwordHasher.hashToken(accessToken),
            refreshTokenHash: _passwordHasher.hashToken(newRefreshToken),
            createdAt: now,
          ),
        );

    return AuthSessionTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      tokenType: 'bearer',
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await (_database.delete(_database.localSessions)
          ..where(
            (session) => session.refreshTokenHash.equals(
              _passwordHasher.hashToken(refreshToken),
            ),
          ))
        .go();
  }

  @override
  Future<AuthUser> me({required String accessToken}) async {
    final session = await (_database.select(_database.localSessions)
          ..where(
            (session) => session.sessionTokenHash.equals(
              _passwordHasher.hashToken(accessToken),
            ),
          ))
        .getSingleOrNull();
    if (session == null) {
      throw _invalidCredentials();
    }

    final user = await (_database.select(_database.localUsers)
          ..where((user) => user.id.equals(session.localUserId)))
        .getSingleOrNull();
    if (user == null || !user.isActive) {
      throw _invalidCredentials();
    }
    return AuthUser(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
    );
  }

  AuthException _invalidCredentials() {
    return const AuthException(
      'Invalid username or password',
      statusCode: 401,
      code: 'INVALID_CREDENTIALS',
    );
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
