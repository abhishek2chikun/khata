import 'package:gotrue/gotrue.dart' as gotrue;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException, AuthUser;

import '../auth/auth_service.dart' as app_auth;
import '../debug/agent_debug_log.dart';

String mapGotrueAuthError(gotrue.AuthException error) {
  final code = error.code ?? '';
  if (code == 'invalid_credentials' ||
      error.message.toLowerCase().contains('invalid login credentials')) {
    return 'Invalid email or password.';
  }
  if (code == 'email_not_confirmed') {
    return 'Confirm your email in Supabase before signing in.';
  }
  return error.message;
}

class HybridAuthService implements app_auth.AuthService {
  HybridAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<app_auth.AuthSessionTokens> login({
    required String username,
    required String password,
  }) async {
    final email = username.trim();
    // #region agent log
    AgentDebugLog.write(
      location: 'hybrid_auth_service.dart:login',
      message: 'login attempt',
      hypothesisId: 'H2-H5',
      data: {
        'emailProvided': email.isNotEmpty,
        'looksLikeEmail': email.contains('@'),
        'supabaseInitialized': true,
      },
    );
    // #endregion
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = response.session;
      if (session == null) {
        throw const app_auth.AuthException(
          'Supabase login did not return a session',
        );
      }
      // #region agent log
      AgentDebugLog.write(
        location: 'hybrid_auth_service.dart:login',
        message: 'login success',
        hypothesisId: 'H1',
        data: {'hasSession': true},
      );
      // #endregion
      return _tokensFromSession(session);
    } on gotrue.AuthException catch (error) {
      // #region agent log
      AgentDebugLog.write(
        location: 'hybrid_auth_service.dart:login',
        message: 'login failed',
        hypothesisId: 'H1-H2',
        data: {
          'code': error.code,
          'statusCode': error.statusCode,
          'errorMessage': error.message,
        },
      );
      // #endregion
      throw app_auth.AuthException(
        mapGotrueAuthError(error),
        statusCode: int.tryParse(error.statusCode ?? ''),
        code: error.code,
      );
    }
  }

  @override
  Future<app_auth.AuthSessionTokens> refresh({required String refreshToken}) async {
    try {
      final response = await _client.auth.refreshSession(refreshToken);
      final session = response.session;
      if (session == null) {
        throw const app_auth.AuthException('Unable to restore Supabase session');
      }
      return _tokensFromSession(session);
    } on gotrue.AuthException catch (error) {
      throw app_auth.AuthException(
        error.message,
        statusCode: int.tryParse(error.statusCode ?? ''),
        code: error.code,
      );
    }
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
