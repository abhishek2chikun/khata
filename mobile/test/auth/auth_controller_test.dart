import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';

void main() {
  group('AuthController', () {
    test('restores cached session without forcing login', () async {
      final authService = FakeAuthService(
        refreshSessionResult: AuthSessionTokens(
          accessToken: 'refreshed-access',
          refreshToken: 'refreshed-refresh',
          tokenType: 'bearer',
        ),
        currentUserResult: const AuthUser(
          id: 'user-1',
          username: 'owner',
          displayName: 'Owner',
        ),
      );
      final sessionStore = InMemorySessionStore(
        initialSession: const StoredSession(
          accessToken: 'cached-access',
          refreshToken: 'cached-refresh',
          tokenType: 'bearer',
        ),
      );

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser?.username, 'owner');
      expect(controller.isRestoringSession, isFalse);
      expect(sessionStore.session?.refreshToken, 'refreshed-refresh');
    });

    test('failed restore clears invalid cached session', () async {
      final authService = FakeAuthService(
        refreshError: const AuthException('Session expired'),
      );
      final sessionStore = InMemorySessionStore(
        initialSession: const StoredSession(
          accessToken: 'cached-access',
          refreshToken: 'stale-refresh',
          tokenType: 'bearer',
        ),
      );

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, isNull);
      expect(sessionStore.session, isNull);
      expect(controller.isRestoringSession, isFalse);
    });

    test('non-AuthException failure during restore clears session and stops restoring state', () async {
      final authService = FakeAuthService(
        refreshException: StateError('bad refresh response'),
      );
      final sessionStore = InMemorySessionStore(
        initialSession: const StoredSession(
          accessToken: 'cached-access',
          refreshToken: 'cached-refresh',
          tokenType: 'bearer',
        ),
      );

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, isNull);
      expect(sessionStore.session, isNull);
      expect(controller.isRestoringSession, isFalse);
    });

    test('me failure after successful refresh during restore clears session state', () async {
      final authService = FakeAuthService(
        refreshSessionResult: AuthSessionTokens(
          accessToken: 'fresh-access',
          refreshToken: 'fresh-refresh',
          tokenType: 'bearer',
        ),
        meException: StateError('malformed me response'),
      );
      final sessionStore = InMemorySessionStore(
        initialSession: const StoredSession(
          accessToken: 'cached-access',
          refreshToken: 'cached-refresh',
          tokenType: 'bearer',
        ),
      );

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(sessionStore.session, isNull);
      expect(controller.isRestoringSession, isFalse);
    });

    test('successful login persists tokens and marks authenticated', () async {
      final authService = FakeAuthService(
        loginSessionResult: AuthSessionTokens(
          accessToken: 'login-access',
          refreshToken: 'login-refresh',
          tokenType: 'bearer',
        ),
        currentUserResult: const AuthUser(
          id: 'user-1',
          username: 'cashier',
          displayName: 'Cashier',
        ),
      );
      final sessionStore = InMemorySessionStore();

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );

      await controller.login(username: 'cashier', password: 'secret123');

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser?.displayName, 'Cashier');
      expect(sessionStore.session?.accessToken, 'login-access');
      expect(authService.lastLoginUsername, 'cashier');
      expect(authService.lastLoginPassword, 'secret123');
      expect(controller.errorMessage, isNull);
    });

    test('non-AuthException failure during login leaves user unauthenticated and shows friendly error', () async {
      final authService = FakeAuthService(
        loginException: StateError('socket failed'),
      );
      final sessionStore = InMemorySessionStore();

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );

      await controller.login(username: 'cashier', password: 'secret123');

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, 'Unable to sign in right now. Please try again.');
      expect(sessionStore.session, isNull);
      expect(controller.isLoggingIn, isFalse);
    });

    test('logout clears persisted session', () async {
      final authService = FakeAuthService(
        refreshSessionResult: AuthSessionTokens(
          accessToken: 'refreshed-access',
          refreshToken: 'refreshed-refresh',
          tokenType: 'bearer',
        ),
        currentUserResult: const AuthUser(
          id: 'user-1',
          username: 'owner',
          displayName: 'Owner',
        ),
      );
      final sessionStore = InMemorySessionStore(
        initialSession: const StoredSession(
          accessToken: 'cached-access',
          refreshToken: 'cached-refresh',
          tokenType: 'bearer',
        ),
      );

      final controller = AuthController(
        authService: authService,
        sessionStore: sessionStore,
      );
      await controller.restoreSession();

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(sessionStore.session, isNull);
      expect(authService.lastLogoutRefreshToken, 'refreshed-refresh');
    });
  });
}

class FakeAuthService implements AuthService {
  FakeAuthService({
    this.loginSessionResult,
    this.refreshSessionResult,
    this.currentUserResult,
    this.loginError,
    this.refreshError,
    this.logoutError,
    this.loginException,
    this.refreshException,
    this.meException,
  });

  final AuthSessionTokens? loginSessionResult;
  final AuthSessionTokens? refreshSessionResult;
  final AuthUser? currentUserResult;
  final AuthException? loginError;
  final AuthException? refreshError;
  final AuthException? logoutError;
  final Object? loginException;
  final Object? refreshException;
  final Object? meException;

  String? lastLoginUsername;
  String? lastLoginPassword;
  String? lastMeAccessToken;
  String? lastLogoutRefreshToken;

  @override
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  }) async {
    lastLoginUsername = username;
    lastLoginPassword = password;
    if (loginException != null) {
      throw loginException!;
    }
    if (loginError != null) {
      throw loginError!;
    }
    return loginSessionResult!;
  }

  @override
  Future<AuthUser> me({required String accessToken}) async {
    lastMeAccessToken = accessToken;
    if (meException != null) {
      throw meException!;
    }
    return currentUserResult!;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    lastLogoutRefreshToken = refreshToken;
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) async {
    if (refreshException != null) {
      throw refreshException!;
    }
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshSessionResult!;
  }
}

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore({StoredSession? initialSession}) : session = initialSession;

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
