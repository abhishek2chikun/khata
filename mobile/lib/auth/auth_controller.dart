import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'session_store.dart';

class AuthController extends ChangeNotifier {
  static const fallbackLoginErrorMessage =
      'Unable to sign in right now. Please try again.';

  AuthController({
    required AuthService authService,
    required SessionStore sessionStore,
  })  : _authService = authService,
        _sessionStore = sessionStore;

  final AuthService _authService;
  final SessionStore _sessionStore;

  AuthUser? _currentUser;
  StoredSession? _session;
  String? _errorMessage;
  bool _isRestoringSession = false;
  bool _isLoggingIn = false;

  AuthUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _session != null;
  bool get isLoggingIn => _isLoggingIn;
  bool get isRestoringSession => _isRestoringSession;

  Future<void> restoreSession() async {
    _setRestoringSession(true);
    _clearTransientState();

    final cachedSession = await _sessionStore.readSession();
    if (cachedSession == null) {
      _session = null;
      _currentUser = null;
      _setRestoringSession(false);
      return;
    }

    try {
      final refreshedTokens = await _authService.refresh(
        refreshToken: cachedSession.refreshToken,
      );
      final storedSession = _storedSessionFromTokens(refreshedTokens);
      final user = await _authService.me(accessToken: storedSession.accessToken);

      await _sessionStore.writeSession(storedSession);
      _session = storedSession;
      _currentUser = user;
    } on Object {
      await _clearSessionState();
    } finally {
      _setRestoringSession(false);
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setLoggingIn(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final tokens = await _authService.login(
        username: username,
        password: password,
      );
      final storedSession = _storedSessionFromTokens(tokens);
      final user = await _authService.me(accessToken: storedSession.accessToken);

      await _sessionStore.writeSession(storedSession);
      _session = storedSession;
      _currentUser = user;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _currentUser = null;
      _session = null;
    } on Object {
      _errorMessage = fallbackLoginErrorMessage;
      _currentUser = null;
      _session = null;
    } finally {
      _setLoggingIn(false);
    }
  }

  Future<void> logout() async {
    final refreshToken = _session?.refreshToken;

    try {
      if (refreshToken != null) {
        await _authService.logout(refreshToken: refreshToken);
      }
    } on AuthException {
      // Local sign-out still succeeds even if the remote session is already gone.
    } finally {
      await _clearSessionState();
    }
  }

  StoredSession _storedSessionFromTokens(AuthSessionTokens tokens) {
    return StoredSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      tokenType: tokens.tokenType,
    );
  }

  Future<void> _clearSessionState() async {
    await _sessionStore.clearSession();
    _session = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearTransientState() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoggingIn(bool value) {
    _isLoggingIn = value;
    notifyListeners();
  }

  void _setRestoringSession(bool value) {
    _isRestoringSession = value;
    notifyListeners();
  }
}
