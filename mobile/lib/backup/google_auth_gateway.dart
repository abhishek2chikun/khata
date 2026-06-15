import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import 'drive_platform.dart';
import 'google_auth_configuration.dart';

typedef DriveAuthClientFactory = auth.AuthClient Function(
  GoogleSignInClientAuthorization authorization,
);

/// Production Google Sign-In adapter for Drive file scope.
class GoogleSignInAuthGateway implements GoogleAuthGateway {
  GoogleSignInAuthGateway({
    GoogleSignIn? signIn,
    DriveAuthClientFactory? authClientFactory,
    GoogleAuthConfiguration? configuration,
  })  : _signIn = signIn ?? GoogleSignIn.instance,
        _authClientFactory = authClientFactory ?? _defaultAuthClientFactory,
        _configuration =
            configuration ?? GoogleAuthConfiguration.fromEnvironment();

  final GoogleSignIn _signIn;
  final DriveAuthClientFactory _authClientFactory;
  final GoogleAuthConfiguration _configuration;
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
    try {
      await _signIn.initialize(
        serverClientId: _configuration.serverClientIdOrNull,
      );
    } on GoogleSignInException catch (error) {
      throw mapGoogleSignInError(error);
    }
    _initialized = true;
    try {
      final lightweight = _signIn.attemptLightweightAuthentication();
      if (lightweight != null) {
        _currentAccount = await lightweight;
      }
    } on GoogleSignInException catch (error) {
      throw mapGoogleSignInError(error);
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
      throw mapGoogleSignInError(error);
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
    final authorization =
        await account.authorizationClient.authorizationForScopes(
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
    var authorization =
        await account.authorizationClient.authorizationForScopes(
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

DriveAuthException mapGoogleSignInError(GoogleSignInException error) {
  if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
    return const DriveAuthException(
      'Google Drive sign-in is not configured for this installed app. Add '
      'a google-services.json containing a web OAuth client, or rebuild '
      'with GOOGLE_DRIVE_SERVER_CLIENT_ID. The Android OAuth client must '
      'match the app package and signing SHA fingerprint.',
    );
  }
  if (error.code == GoogleSignInExceptionCode.canceled) {
    return const DriveAuthException(
      'Google sign-in was canceled. If this appears after choosing an '
      'account, verify the app package, signing SHA, and OAuth client ID.',
    );
  }
  return DriveAuthException(
    error.description ?? 'Google sign-in failed. Please try again.',
  );
}
