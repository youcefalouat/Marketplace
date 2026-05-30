import 'package:google_sign_in/google_sign_in.dart';

/// Result of a social sign-in attempt.
class SocialAuthResult {
  final String provider;
  final String providerId;
  final String email;
  final String name;
  final String? accessToken;

  SocialAuthResult({
    required this.provider,
    required this.providerId,
    required this.email,
    required this.name,
    this.accessToken,
  });
}

class SocialAuthService {
  static bool _googleInitialized = false;

  /// Web client ID from google-services.json (client_type 3).
  static const _serverClientId =
      '269847662498-cgtchnggudvqejsf7746lckdcpo9tbvr.apps.googleusercontent.com';

  /// Ensure GoogleSignIn.instance is initialized exactly once.
  static Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
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

  /// Sign out from Google (useful on logout).
  static Future<void> signOut() async {
    try {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
