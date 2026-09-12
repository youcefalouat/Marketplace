import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Result of a social sign-in attempt.
class SocialAuthResult {
  final String provider;
  final String providerId;
  final String email;
  final String name;
  final String? accessToken;
  final String? identityToken;
  final String? authorizationCode;
  final String? firstName;
  final String? lastName;

  SocialAuthResult({
    required this.provider,
    required this.providerId,
    required this.email,
    required this.name,
    this.accessToken,
    this.identityToken,
    this.authorizationCode,
    this.firstName,
    this.lastName,
  });
}

class SocialAuthService {
  static bool _googleInitialized = false;

  /// Web client ID from google-services.json (client_type 3).
  static const _serverClientId =
      '269847662498-cgtchnggudvqejsf7746lckdcpo9tbvr.apps.googleusercontent.com';

  // The iOS OAuth client ID can be supplied by the build (for example by
  // Codemagic's --dart-define) when GoogleService-Info.plist is not checked
  // into the repository. If it is omitted, the plugin reads GIDClientID from
  // ios/Runner/Info.plist.
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Ensure GoogleSignIn.instance is initialized exactly once.
  static Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _iosClientId.isEmpty ? null : _iosClientId,
      serverClientId: _serverClientId,
    );
    _googleInitialized = true;
  }

  /// Launch the native Google sign-in flow. Returns null if the user cancels.
  static Future<SocialAuthResult?> signInWithGoogle() async {
    try {
      await _ensureGoogleInit();
      final account = await GoogleSignIn.instance.authenticate();

      return SocialAuthResult(
        provider: 'Google',
        providerId: account.id,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        accessToken: null,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw Exception('Erreur Google Sign-In: ${e.description ?? e.code}');
    } catch (e) {
      throw Exception('Erreur Google Sign-In: $e');
    }
  }

  /// Launch the native Apple sign-in flow. Returns null if the user cancels.
  static Future<SocialAuthResult?> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('La connexion avec Apple n’est pas disponible');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple n’a pas fourni de jeton d’identité');
      }

      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .where((part) => part.isNotEmpty)
          .join(' ');

      return SocialAuthResult(
        provider: 'Apple',
        providerId: credential.userIdentifier ?? '',
        email: credential.email ?? '',
        name: name.isEmpty ? 'Utilisateur' : name,
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw Exception('Erreur Apple Sign-In: ${e.message}');
    } on SignInWithAppleException catch (e) {
      throw Exception('Erreur Apple Sign-In: $e');
    } catch (e) {
      throw Exception('Erreur Apple Sign-In: $e');
    }
  }

  /// Sign out from Google (useful on logout).
  static Future<void> signOut() async {
    try {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
