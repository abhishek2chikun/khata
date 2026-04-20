import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/screens/login_screen.dart';

void main() {
  testWidgets('login screen submits credentials and reflects loading/error state appropriately', (tester) async {
    final authService = FakeAuthService();
    final controller = AuthController(
      authService: authService,
      sessionStore: InMemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginScreen(controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'owner');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(authService.lastLoginUsername, 'owner');
    expect(authService.lastLoginPassword, 'secret123');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    authService.completeLoginError(const AuthException('Invalid username or password'));
    await tester.pump();

    expect(find.text('Invalid username or password'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

class FakeAuthService implements AuthService {
  Completer<AuthSessionTokens>? _loginCompleter;

  String? lastLoginUsername;
  String? lastLoginPassword;

  @override
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  }) {
    lastLoginUsername = username;
    lastLoginPassword = password;
    _loginCompleter = Completer<AuthSessionTokens>();
    return _loginCompleter!.future;
  }

  void completeLoginError(AuthException error) {
    _loginCompleter!.completeError(error);
  }

  @override
  Future<AuthUser> me({required String accessToken}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) {
    throw UnimplementedError();
  }
}

class InMemorySessionStore implements SessionStore {
  StoredSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredSession session) async {
    this.session = session;
  }
}
