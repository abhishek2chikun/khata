import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import 'drive_platform.dart';

typedef DriveAuthClientFactory = auth.AuthClient Function(
  GoogleSignInClientAuthorization authorization,
);

/// Production Google Sign-In adapter for Drive file scope.
class GoogleSignInAuthGateway implements GoogleAuthGateway {
  GoogleSignInAuthGateway({
    GoogleSignIn? signIn,
    DriveAuthClientFactory? authClientFactory,
  })  : _signIn = signIn ?? GoogleSignIn.instance,
        _authClientFactory = authClientFactory ?? _defaultAuthClientFactory;

  final GoogleSignIn _signIn;
  final DriveAuthClientFactory _authClientFactory;
  GoogleSignInAccount? _currentAccount;
  var _initialized = false;

  static auth.AuthClient _defaultAuthClientFactory(
    GoogleSignInClientAuthorization authorization,
  ) {
    return authorization.authClient(scopes: GoogleAuthGateway.driveScopes);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _signIn.initialize();
    _initialized = true;
    final lightweight = _signIn.attemptLightweightAuthentication();
    if (lightweight != null) {
      _currentAccount = await lightweight;
    }
  }

  @override
  Future<bool> isSignedIn() async {
    await _ensureInitialized();
    return _currentAccount != null;
  }

  @override
  Future<String?> accountEmail() async {
    await _ensureInitialized();
    return _currentAccount?.email;
  }

  @override
  Future<void> signIn() async {
    await _ensureInitialized();
    try {
      _currentAccount = await _signIn.authenticate(
        scopeHint: GoogleAuthGateway.driveScopes,
      );
      await _currentAccount!.authorizationClient.authorizeScopes(
        GoogleAuthGateway.driveScopes,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const DriveAuthException('sign in canceled');
      }
      throw DriveAuthException(
        error.description ?? 'Google sign in failed',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _signIn.signOut();
    _currentAccount = null;
  }

  @override
  Future<bool> hasDriveAccess() async {
    await _ensureInitialized();
    final account = _currentAccount;
    if (account == null) {
      return false;
    }
    final authorization = await account.authorizationClient.authorizationForScopes(
      GoogleAuthGateway.driveScopes,
    );
    return authorization != null;
  }

  /// Returns an authenticated Drive client, optionally prompting for scopes.
  Future<auth.AuthClient?> createDriveAuthClient({
    bool promptIfUnauthorized = false,
  }) async {
    await _ensureInitialized();
    final account = _currentAccount;
    if (account == null) {
      return null;
    }
    var authorization = await account.authorizationClient.authorizationForScopes(
      GoogleAuthGateway.driveScopes,
    );
    if (authorization == null && promptIfUnauthorized) {
      authorization = await account.authorizationClient.authorizeScopes(
        GoogleAuthGateway.driveScopes,
      );
    }
    if (authorization == null) {
      return null;
    }
    return _authClientFactory(authorization);
  }
}
