import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException, AuthUser;

import '../auth/auth_service.dart' as app_auth;

class HybridAuthService implements app_auth.AuthService {
  HybridAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<app_auth.AuthSessionTokens> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: username.trim(),
      password: password,
    );
    final session = response.session;
    if (session == null) {
      throw const app_auth.AuthException('Supabase login did not return a session');
    }
    return _tokensFromSession(session);
  }

  @override
  Future<app_auth.AuthSessionTokens> refresh({required String refreshToken}) async {
    final response = await _client.auth.refreshSession(refreshToken);
    final session = response.session;
    if (session == null) {
      throw const app_auth.AuthException('Unable to restore Supabase session');
    }
    return _tokensFromSession(session);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _client.auth.signOut();
  }

  @override
  Future<app_auth.AuthUser> me({required String accessToken}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const app_auth.AuthException('No active Supabase session');
    }
    return app_auth.AuthUser(
      id: user.id,
      username: user.email ?? user.id,
      displayName: user.userMetadata?['display_name'] as String? ?? user.email,
    );
  }

  app_auth.AuthSessionTokens _tokensFromSession(Session session) {
    return app_auth.AuthSessionTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      tokenType: session.tokenType,
    );
  }
}

class HybridConnectivityGate {
  HybridConnectivityGate(this._client);

  final SupabaseClient _client;

  void requireOnlineSession() {
    if (_client.auth.currentSession == null) {
      throw const HybridOfflineException(
        'Connect and sign in before saving official records.',
      );
    }
  }
}

class HybridOfflineException implements Exception {
  const HybridOfflineException(this.message);

  final String message;

  @override
  String toString() => message;
}
