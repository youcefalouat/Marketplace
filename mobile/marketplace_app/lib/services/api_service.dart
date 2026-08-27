import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../models/seller_models.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';

class ApiService {
  static String get baseUrl {
    return AppConfig.apiBaseUrl;
  }

  /// Converts a relative image path to a full URL.
  /// Returns null if the input is null.
  static String? getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http')) return relativePath;
    final serverBase = baseUrl.replaceFirst('/api', '');
    // Fix #8: Strip leading slash to prevent double-slash in URL
    final cleanPath =
        relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$serverBase/$cleanPath';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  http.Client _client = http.Client();
  String? _token;
  User? _currentUser;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Public token getter
  String? get token => _token;

  // Token management
  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    _token ??= await _storage.read(key: 'auth_token');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'auth_token');
  }

  User? get currentUser => _currentUser;

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  bool _shouldRetryException(Object error) {
    if (error is SocketException || error is HttpException) {
      return true;
    }

    // TimeoutException means a dead/stale connection — don't retry immediately.
    if (error is TimeoutException) return false;

    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      return message
              .contains('connection closed before full header was received') ||
          message.contains('connection closed');
    }

    return false;
  }

  bool _shouldRetryStatus(int statusCode) =>
      statusCode == 408 ||
      statusCode == 429 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  Duration _retryDelay(int attempt) =>
      Duration(milliseconds: 300 * (1 << (attempt - 1)));

  /// Replace the shared HTTP client to flush the connection pool.
  /// Call this when the app resumes from background (Doze kills TCP sockets)
  /// or after a timeout indicates a stale connection.
  void flushHttpClient() {
    _client = http.Client();
    // The old client is abandoned; its sockets will be closed by the OS.
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await request().timeout(timeout);
        if (!_shouldRetryStatus(response.statusCode) || attempt == 3) {
          return response;
        }
      } catch (error) {
        lastError = error;
        if (error is TimeoutException) {
          // Stale TCP connection in the pool — flush it and retry once
          // with a fresh client. The network is likely fine (SignalR shows it).
          flushHttpClient();
          if (attempt >= 2) rethrow;
        } else if (!_shouldRetryException(error) || attempt == 3) {
          rethrow;
        }
      }

      await Future.delayed(_retryDelay(attempt));
    }

    throw lastError ?? Exception('Network request failed');
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return _sendWithRetry(() => _client.get(uri, headers: headers));
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _sendWithRetry(
        () => _client.post(uri, headers: headers, body: body));
  }

  Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _sendWithRetry(() => _client.put(uri, headers: headers, body: body));
  }

  Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return _sendWithRetry(() => _client.delete(uri, headers: headers));
  }

  /// Safely extract an error message from an HTTP response body.
  /// Returns [fallback] if the body is empty or not valid JSON.
  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      if (response.body.isEmpty) return fallback;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message'] as String? ?? fallback;
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<http.Response> _sendMultipartWithRetry(
    Future<http.MultipartRequest> Function() buildRequest, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final request = await buildRequest();
        final streamedResponse = await _client.send(request).timeout(timeout);
        final response = await http.Response.fromStream(streamedResponse);
        if (!_shouldRetryStatus(response.statusCode) || attempt == 3) {
          return response;
        }
      } catch (error) {
        lastError = error;
        if (!_shouldRetryException(error) || attempt == 3) {
          rethrow;
        }
      }

      await Future.delayed(_retryDelay(attempt));
    }

    throw lastError ?? Exception('Multipart request failed');
  }

  /// Generic authenticated HTTP request helper used by ChatService.
  Future<http.Response> authenticatedRequest(
    String path, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl$path');

    switch (method.toUpperCase()) {
      case 'GET':
        return await _get(uri, headers: headers);
      case 'POST':
        return await _post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await _put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await _delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // ─── Auth endpoints ───

  Future<RegisterResult> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required int wilayaId,
    required int communeId,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'wilayaId': wilayaId,
        'communeId': communeId,
      }),
    );

    if (response.statusCode == 200) {
      final result = RegisterResult.fromJson(jsonDecode(response.body));
      await setToken(result.token);
      _currentUser = result.user;
      return result;
    } else {
      throw Exception(
          _extractErrorMessage(response, 'Erreur lors de l\'inscription'));
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await setToken(authResponse.token);
      _currentUser = authResponse.user;
      return authResponse;
    } else if (response.statusCode == 401) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final errorCode = data['errorCode'] as String?;
      if (errorCode == 'EMAIL_NOT_VERIFIED') {
        throw Exception(
            'EMAIL_NOT_VERIFIED:${data['message'] ?? 'Veuillez vérifier votre adresse email.'}');
      }
      throw Exception(data['message'] ?? 'Email ou mot de passe incorrect');
    } else {
      throw Exception(
          _extractErrorMessage(response, 'Email ou mot de passe incorrect'));
    }
  }

  Future<AuthResponse> socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String name,
    String? accessToken,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/social-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'providerId': providerId,
        'email': email,
        'name': name,
        'accessToken': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await setToken(authResponse.token);
      _currentUser = authResponse.user;
      return authResponse;
    } else {
      throw Exception(
          _extractErrorMessage(response, 'Erreur de connexion sociale'));
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<void> requestAccountDeletion() async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/auth/request-account-deletion'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(
          response, 'Impossible de demander la suppression du compte'));
    }
  }

  // ─── Phone OTP Login (unauthenticated) ───

  /// Request an OTP for phone-based login/registration.
  Future<void> requestPhoneLoginOtp(String phone) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/phone-login-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          _extractErrorMessage(response, "Erreur lors de l'envoi du code"));
    }
  }

  /// Verify phone OTP and receive auth token (login or auto-register).
  Future<AuthResponse> verifyPhoneLoginOtp(String phone, String code) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/phone-login-verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await setToken(authResponse.token);
      _currentUser = authResponse.user;
      return authResponse;
    } else {
      throw Exception(_extractErrorMessage(response, 'Code invalide'));
    }
  }

  // ─── Phone verification endpoints ───

  Future<Map<String, dynamic>> sendVerificationCode(String phone) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/auth/send-verification'),
      headers: headers,
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          _extractErrorMessage(response, 'Erreur lors de l\'envoi du code'));
    }
  }

  Future<User> verifyPhone(String code) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/auth/verify-phone'),
      headers: headers,
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      _currentUser = user;
      return user;
    } else {
      throw Exception(_extractErrorMessage(response, 'Code invalide'));
    }
  }

  // ─── Email verification endpoints ───

  Future<Map<String, dynamic>> sendEmailVerificationCode(String email) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/auth/send-email-verification'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          _extractErrorMessage(response, 'Erreur lors de l\'envoi du code'));
    }
  }

  Future<User> verifyEmail(String email, String code) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: headers,
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      _currentUser = user;
      return user;
    } else {
      throw Exception(_extractErrorMessage(response, 'Code invalide'));
    }
  }

  /// Unauthenticated resend — used from EmailVerificationScreen without a token.
  Future<void> resendVerificationEmail(String email) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 429) {
      throw Exception(
          'Veuillez patienter 60 secondes avant de renvoyer un email.');
    }
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(
          response, 'Erreur lors de l\'envoi de l\'email'));
    }
  }

  // ─── Legal content endpoints ───

  Future<LegalContent> getTerms() async {
    final headers = await _authHeaders();
    final response = await _get(
      Uri.parse('$baseUrl/public/terms'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return LegalContent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement des conditions');
    }
  }

  Future<LegalContent> getPrivacy() async {
    final headers = await _authHeaders();
    final response = await _get(
      Uri.parse('$baseUrl/public/privacy'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return LegalContent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement de la politique');
    }
  }

  // ─── User endpoints ───

  Future<User> getProfile() async {
    final headers = await _authHeaders();
    final response = await _get(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      _currentUser = user;
      return user;
    } else {
      throw Exception('Erreur lors de la récupération du profil');
    }
  }

  Future<User> updateProfile({
    required String name,
    required String phone,
    required int wilayaId,
    required int communeId,
  }) async {
    final headers = await _authHeaders();
    final response = await _put(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'wilayaId': wilayaId,
        'communeId': communeId,
      }),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      _currentUser = user;
      return user;
    } else {
      throw Exception('Erreur lors de la mise à jour du profil');
    }
  }

  Future<void> updateFcmToken(String token) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/users/fcm-token'),
      headers: headers,
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour du token FCM');
    }
  }

  // ─── Locations endpoints ───

  Future<List<Wilaya>> getWilayas() async {
    final headers = await _authHeaders();
    final response = await _get(
      Uri.parse('$baseUrl/locations/wilayas'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Wilaya.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des wilayas');
    }
  }

  Future<List<Commune>> getCommunes(int wilayaId) async {
    final headers = await _authHeaders();
    final response = await _get(
      Uri.parse('$baseUrl/locations/wilayas/$wilayaId/communes'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Commune.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des communes');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final headers = await _authHeaders();
    final response = await _get(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des catégories');
    }
  }

  // ─── Admin Categories endpoints ───

  Future<CategoryModel> createCategory({
    required String name,
    String arName = '',
    required String slug,
    String? imageUrl,
    int? parentId,
  }) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'arName': arName,
        'slug': slug,
        'imageUrl': imageUrl,
        'parentId': parentId,
      }),
    );

    if (response.statusCode == 201) {
      return CategoryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_extractErrorMessage(
          response, 'Erreur lors de la création de la catégorie'));
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    String arName = '',
    required String slug,
    String? imageUrl,
    int? parentId,
  }) async {
    final headers = await _authHeaders();
    final response = await _put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'arName': arName,
        'slug': slug,
        'imageUrl': imageUrl,
        'parentId': parentId,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception(_extractErrorMessage(
          response, 'Erreur lors de la mise à jour de la catégorie'));
    }
  }

  Future<void> deleteCategory(int id) async {
    final headers = await _authHeaders();
    final response = await _delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception(_extractErrorMessage(
          response, 'Erreur lors de la suppression de la catégorie'));
    }
  }

  // ─── Annonces endpoints ───

  Future<PaginatedResponse<AnnonceListItem>> getAnnonces({
    int? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    List<int>? wilayaIds,
    List<int>? communeIds,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (categoryId != null) queryParams['categoryId'] = categoryId.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (wilayaIds != null && wilayaIds.isNotEmpty) {
      queryParams['wilayaIds'] = wilayaIds.map((id) => id.toString()).toList();
    }
    if (communeIds != null && communeIds.isNotEmpty) {
      queryParams['communeIds'] =
          communeIds.map((id) => id.toString()).toList();
    }

    final uri =
        Uri.parse('$baseUrl/annonces').replace(queryParameters: queryParams);
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final items = (json['items'] as List)
          .map((item) => AnnonceListItem.fromJson(item))
          .toList();

      return PaginatedResponse(
        items: items,
        totalCount: json['totalCount'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        totalPages: json['totalPages'] as int,
      );
    } else {
      throw Exception('Erreur lors de la récupération des annonces');
    }
  }

  Future<List<AnnonceListItem>> getFeaturedAnnonces({
    int count = 20,
    int? communeId,
    int? wilayaId,
  }) async {
    final params = <String, String>{'count': count.toString()};
    if (communeId != null) params['communeId'] = communeId.toString();
    if (wilayaId != null) params['wilayaId'] = wilayaId.toString();
    final uri = Uri.parse('$baseUrl/annonces/featured')
        .replace(queryParameters: params);
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json.map((e) => AnnonceListItem.fromJson(e)).toList();
    } else {
      throw Exception(
          'Erreur lors de la récupération des annonces mises en avant');
    }
  }

  Future<AnnonceDetail> getAnnonceDetail(int id) async {
    debugPrint('[API] getAnnonceDetail($id) - requesting...');
    final headers = await _authHeaders();
    final response =
        await _get(Uri.parse('$baseUrl/annonces/$id'), headers: headers);

    debugPrint('[API] getAnnonceDetail($id) - status: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        return AnnonceDetail.fromJson(jsonDecode(response.body));
      } catch (e) {
        debugPrint('[API] getAnnonceDetail($id) - JSON parse error: $e');
        throw Exception('Erreur de chargement des données de l\'annonce');
      }
    } else {
      // Try to extract the error message from the backend response
      String errorMessage;
      try {
        final error = jsonDecode(response.body);
        errorMessage = error['message'] as String? ?? '';
        debugPrint(
            '[API] getAnnonceDetail($id) - backend error: $errorMessage');
      } catch (_) {
        errorMessage = '';
        debugPrint(
            '[API] getAnnonceDetail($id) - non-JSON error body: ${response.body}');
      }

      if (errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

      switch (response.statusCode) {
        case 404:
          throw Exception('Annonce supprimée ou indisponible');
        case 403:
          throw Exception('Accès refusé à cette annonce');
        case 500:
          throw Exception('Erreur serveur. Veuillez réessayer.');
        default:
          throw Exception('Erreur de chargement (code ${response.statusCode})');
      }
    }
  }

  Future<AnnonceDetail> createAnnonce({
    required int categoryId,
    int? parentCategoryId,
    required String title,
    required String description,
    required double price,
    required int state,
    String? phone,
    int? wilayaId,
    int? communeId,
    bool isExchange = false,
    bool showPhone = true,
    bool reservationEnabled = false,
    required List<File> images,
  }) async {
    final token = await getToken();

    final response = await _sendMultipartWithRetry(() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/annonces'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['categoryId'] = categoryId.toString();
      if (parentCategoryId != null) {
        request.fields['parentCategoryId'] = parentCategoryId.toString();
      }
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['state'] = state.toString();
      request.fields['isExchange'] = isExchange.toString();
      request.fields['showPhone'] = showPhone.toString();
      request.fields['reservationEnabled'] = reservationEnabled.toString();
      if (phone != null) request.fields['phone'] = phone;
      if (wilayaId != null) request.fields['wilayaId'] = wilayaId.toString();
      if (communeId != null) request.fields['communeId'] = communeId.toString();

      for (final file in images) {
        if (!file.existsSync()) continue;

        final extension = file.path.split('.').last.toLowerCase();
        MediaType? mediaType;

        if (extension == 'webp') {
          mediaType = MediaType('image', 'webp');
        } else if (extension == 'jpg' || extension == 'jpeg') {
          mediaType = MediaType('image', 'jpeg');
        } else if (extension == 'png') {
          mediaType = MediaType('image', 'png');
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: mediaType,
          ),
        );
      }

      return request;
    });

    if (response.statusCode == 201) {
      return AnnonceDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_extractErrorMessage(
          response, 'Erreur lors de la création de l\'annonce'));
    }
  }

  Future<PaginatedResponse<MyAnnonce>> getMyAnnonces({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/annonces/my').replace(queryParameters: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, MyAnnonce.fromJson);
    } else {
      throw Exception('Erreur lors de la récupération de vos annonces');
    }
  }

  Future<PaginatedResponse<Conversation>> getAnnonceConversations(
    int annonceId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri =
        Uri.parse('$baseUrl/chat/conversations').replace(queryParameters: {
      'annonceId': annonceId.toString(),
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, Conversation.fromJson);
    } else {
      throw Exception('Erreur lors de la récupération des conversations');
    }
  }

  Future<PaginatedResponse<Reservation>> getAnnonceReservations(
    int annonceId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/annonces/$annonceId/reservations')
        .replace(queryParameters: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, Reservation.fromJson);
    } else {
      throw Exception('Erreur lors de la récupération des réservations');
    }
  }

  Future<MyAnnonce> deleteAnnonce(int id, AnnonceDeletionStatus status) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/annonces/$id/delete'),
      headers: headers,
      body: jsonEncode({'status': status.apiValue}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'annonce');
    }

    return MyAnnonce.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ─── Ratings endpoints ───

  Future<void> submitRating({
    required int sellerId,
    required num rating,
    String? comment,
  }) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/ratings'),
      headers: headers,
      body: jsonEncode({
        'sellerId': sellerId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          _extractErrorMessage(response, 'Erreur lors de l\'envoi de la note'));
    }
  }

  // ─── Reservation endpoints ───

  Future<ReservationCreatedResult> createReservation(int annonceId) async {
    final headers = await _authHeaders();
    final response = await _post(
      Uri.parse('$baseUrl/reservations'),
      headers: headers,
      body: jsonEncode({'annonceId': annonceId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReservationCreatedResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(
        _extractErrorMessage(response, 'Erreur lors de la réservation'));
  }

  // ─── Admin/Seller chat on annonce endpoints ───

  Future<ModerationThread> getModerationThread(int threadId) async {
    final response = await authenticatedRequest(
      '/moderation/threads/$threadId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return ModerationThread.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_extractErrorMessage(response, 'Conversation introuvable'));
  }

  Future<ModerationMessage> sendModerationMessage(
    int threadId,
    String content,
  ) async {
    final response = await authenticatedRequest(
      '/moderation/threads/$threadId/messages',
      method: 'POST',
      body: {'content': content},
    );

    if (response.statusCode == 200) {
      return ModerationMessage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
        _extractErrorMessage(response, 'Erreur lors de l\'envoi du message'));
  }

  // ─── Seller / Top Verified Users endpoints ───

  Future<List<TopVerifiedUser>> getTopVerifiedUsers(
      {int? communeId, int? wilayaId}) async {
    final params = <String, String>{};
    if (communeId != null) params['communeId'] = communeId.toString();
    if (wilayaId != null) params['wilayaId'] = wilayaId.toString();
    final uri = Uri.parse('$baseUrl/users/top-verified')
        .replace(queryParameters: params);
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json
          .map((e) => TopVerifiedUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors de la récupération des vendeurs vérifiés');
  }

  Future<SellerProfile> getSellerProfile(int sellerId) async {
    final uri = Uri.parse('$baseUrl/sellers/$sellerId');
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);
    if (response.statusCode == 200) {
      return SellerProfile.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Vendeur introuvable');
  }

  Future<PaginatedResponse<AnnonceListItem>> getSellerAnnonces(int sellerId,
      {int page = 1}) async {
    final uri = Uri.parse('$baseUrl/sellers/$sellerId/annonces')
        .replace(queryParameters: {'page': page.toString()});
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (e) => AnnonceListItem.fromJson(e),
      );
    }
    throw Exception('Erreur lors de la récupération des annonces du vendeur');
  }

  Future<PaginatedResponse<SellerReview>> getSellerReviews(int sellerId,
      {int page = 1}) async {
    final uri = Uri.parse('$baseUrl/sellers/$sellerId/reviews')
        .replace(queryParameters: {'page': page.toString()});
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (e) => SellerReview.fromJson(e),
      );
    }
    throw Exception('Erreur lors de la récupération des avis');
  }

  Future<PaginatedResponse<UserSearchResult>> searchUsers(String query,
      {int page = 1}) async {
    final uri = Uri.parse('$baseUrl/users/search')
        .replace(queryParameters: {'query': query, 'page': page.toString()});
    final headers = await _authHeaders();
    final response = await _get(uri, headers: headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (e) => UserSearchResult.fromJson(e),
      );
    }
    throw Exception('Erreur lors de la recherche');
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/users/avatar');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    // Always supply an explicit content-type: image_picker on Android can
    // return temp files without an extension, causing fromPath to fall back
    // to application/octet-stream, which the backend rejects.
    final mimeType = await _detectImageMimeType(imageFile);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['avatarUrl'] as String?;
    }
    throw Exception(_extractErrorMessage(
        response, 'Erreur lors du téléchargement de l\'avatar'));
  }

  /// Detects image MIME type: extension first, then magic bytes, then jpeg fallback.
  static Future<String> _detectImageMimeType(File file) async {
    const extMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
    };
    final ext = file.path.split('.').last.toLowerCase();
    if (extMap.containsKey(ext)) return extMap[ext]!;

    // No usable extension — inspect magic bytes
    final bytes =
        await file.openRead(0, 16).expand<int>((chunk) => chunk).toList();
    if (bytes.length >= 3) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
        return 'image/jpeg';
      if (bytes.length >= 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) return 'image/png';
      if (bytes.length >= 4 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) return 'image/webp';
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46)
        return 'image/gif';
    }

    return 'image/jpeg'; // safe default for camera/gallery photos
  }

  // ─── Admin endpoints ───

  Future<PaginatedResponse<AdminUser>> getAdminSellers({
    String verified = 'all',
    String? search,
    int page = 1,
  }) async {
    final params = <String, String>{
      'verified': verified,
      'page': page.toString()
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$baseUrl/admin/users/sellers')
        .replace(queryParameters: params);
    final token = await getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await _get(uri, headers: headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (e) => AdminUser.fromJson(e),
      );
    }
    throw Exception('Erreur lors de la récupération des vendeurs');
  }

  Future<void> setVerifiedSeller(int userId, {required bool isVerified}) async {
    final response = await authenticatedRequest(
      '/admin/users/$userId/verified-seller',
      method: 'PUT',
      body: {'isVerifiedSeller': isVerified},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      await getProfile();
      return true;
    } catch (e) {
      await clearToken();
      return false;
    }
  }
}
