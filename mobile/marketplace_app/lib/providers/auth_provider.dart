import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/social_auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _emailVerificationRequired = false;
  bool _emailNotVerified = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user == null;
  bool get isAdmin => _user?.role.toLowerCase() == 'admin';
  String? get token => _apiService.token;
  bool get emailVerificationRequired => _emailVerificationRequired;
  bool get emailNotVerified => _emailNotVerified;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _apiService.isAuthenticated();
      if (isAuth) {
        _user = _apiService.currentUser;
        _updateFcmToken();
      }
    } catch (e) {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _updateFcmToken() async {
    try {
      if (!kIsWeb) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _apiService.updateFcmToken(token);
        }
      }
    } catch (e) {
      debugPrint('Erreur FCM Token: $e');
    }
  }

  /// Refresh current user profile from the API.
  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      _user = await _apiService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  // Register — returns true on success, sets emailVerificationRequired flag
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required int wilayaId,
    required int communeId,
  }) async {
    _isLoading = true;
    _error = null;
    _emailVerificationRequired = false;
    notifyListeners();

    try {
      final result = await _apiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        wilayaId: wilayaId,
        communeId: communeId,
      );
      _user = result.user;
      _emailVerificationRequired = result.emailVerificationRequired;
      _updateFcmToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login — sets emailNotVerified flag when EMAIL_NOT_VERIFIED error
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _emailNotVerified = false;
    notifyListeners();

    try {
      final authResponse = await _apiService.login(
        email: email,
        password: password,
      );
      _user = authResponse.user;
      _updateFcmToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.startsWith('EMAIL_NOT_VERIFIED:')) {
        _emailNotVerified = true;
        _error = msg.substring('EMAIL_NOT_VERIFIED:'.length);
      } else {
        _error = msg;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Social login (Google)
  Future<bool> socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String name,
    String? accessToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.socialLogin(
        provider: provider,
        providerId: providerId,
        email: email,
        name: name,
        accessToken: accessToken,
      );
      _user = authResponse.user;
      _updateFcmToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Phone OTP Login ───

  Future<void> requestPhoneOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.requestPhoneLoginOtp(phone);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.verifyPhoneLoginOtp(phone, code);
      _user = authResponse.user;
      _updateFcmToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required int wilayaId,
    required int communeId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.updateProfile(
        name: name,
        phone: phone,
        wilayaId: wilayaId,
        communeId: communeId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Email verification
  Future<Map<String, dynamic>> sendEmailVerification() async {
    if (_user == null) throw Exception('Non connecté');
    return await _apiService.sendEmailVerificationCode(_user!.email);
  }

  Future<bool> verifyEmail(String code) async {
    if (_user == null) throw Exception('Non connecté');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.verifyEmail(_user!.email, code);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    await SocialAuthService.signOut();
    _user = null;
    _emailVerificationRequired = false;
    _emailNotVerified = false;
    notifyListeners();
  }

  Future<bool> requestAccountDeletion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.requestAccountDeletion();
      await logout();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    try {
      final avatarUrl = await _apiService.uploadAvatar(imageFile);
      if (avatarUrl != null && _user != null) {
        _user = User(
          id: _user!.id,
          email: _user!.email,
          name: _user!.name,
          phone: _user!.phone,
          wilayaId: _user!.wilayaId,
          communeId: _user!.communeId,
          wilayaName: _user!.wilayaName,
          communeName: _user!.communeName,
          role: _user!.role,
          provider: _user!.provider,
          providerId: _user!.providerId,
          phoneVerified: _user!.phoneVerified,
          emailVerified: _user!.emailVerified,
          avatarUrl: avatarUrl,
          isVerifiedSeller: _user!.isVerifiedSeller,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    _emailNotVerified = false;
    notifyListeners();
  }
}
