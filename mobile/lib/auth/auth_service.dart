class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class AuthSessionTokens {
  const AuthSessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  factory AuthSessionTokens.fromJson(Map<String, dynamic> json) {
    return AuthSessionTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String username;
  final String? displayName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
    );
  }
}

abstract class AuthService {
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  });

  Future<AuthSessionTokens> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<AuthUser> me({required String accessToken});
}
