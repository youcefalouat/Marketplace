import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'package:http_parser/http_parser.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // Automatic detection of the API URL
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';

    // On Android Emulator, 10.0.2.2 points to the host's localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }

    // For iOS Simulator, Windows, macOS
    return 'http://localhost:5000/api';
  }

  /// Converts a relative image path to a full URL.
  /// Returns null if the input is null.
  static String? getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http')) return relativePath;
    final serverBase = baseUrl.replaceFirst('/api', '');
    // Fix #8: Strip leading slash to prevent double-slash in URL
    final cleanPath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$serverBase/$cleanPath';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri,
            headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT':
        return await http.put(uri,
            headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // ─── Auth endpoints ───

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required int wilayaId,
    required int communeId,
  }) async {
    final response = await http.post(
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
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await setToken(authResponse.token);
      _currentUser = authResponse.user;
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'inscription');
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
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
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Email ou mot de passe incorrect');
    }
  }

  Future<AuthResponse> socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String name,
    String? accessToken,
  }) async {
    final response = await http.post(
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
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de connexion sociale');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  // ─── Phone verification endpoints ───

  Future<Map<String, dynamic>> sendVerificationCode(String phone) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-verification'),
      headers: headers,
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'envoi du code');
    }
  }

  Future<User> verifyPhone(String code) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-phone'),
      headers: headers,
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      _currentUser = user;
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Code invalide');
    }
  }

  // ─── Email verification endpoints ───

  Future<Map<String, dynamic>> sendEmailVerificationCode(String email) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-email-verification'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'envoi du code');
    }
  }

  Future<User> verifyEmail(String email, String code) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: headers,
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      _currentUser = user;
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Code invalide');
    }
  }

  // ─── User endpoints ───

  Future<User> getProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
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
    final response = await http.put(
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

  // ─── Locations endpoints ───

  Future<List<Wilaya>> getWilayas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations/wilayas'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Wilaya.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des wilayas');
    }
  }

  Future<List<Commune>> getCommunes(int wilayaId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations/wilayas/$wilayaId/communes'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Commune.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des communes');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
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
    required String slug,
    int? parentId,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'slug': slug,
        'parentId': parentId,
      }),
    );

    if (response.statusCode == 201) {
      return CategoryModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Erreur lors de la création de la catégorie');
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String slug,
    int? parentId,
  }) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'slug': slug,
        'parentId': parentId,
      }),
    );

    if (response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Erreur lors de la mise à jour de la catégorie');
    }
  }

  Future<void> deleteCategory(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Erreur lors de la suppression de la catégorie');
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
    final response = await http.get(uri);

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

  Future<List<AnnonceListItem>> getFeaturedAnnonces({int count = 20}) async {
    final uri = Uri.parse('$baseUrl/annonces/featured')
        .replace(queryParameters: {'count': count.toString()});
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json
          .map((e) => AnnonceListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erreur lors de la récupération des annonces mises en avant');
    }
  }

  Future<AnnonceDetail> getAnnonceDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/annonces/$id'));

    if (response.statusCode == 200) {
      return AnnonceDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Annonce non trouvée');
    }
  }

  Future<AnnonceDetail> createAnnonce({
    required int categoryId,
    required String title,
    required String description,
    required double price,
    required int state,
    String? phone,
    int? wilayaId,
    int? communeId,
    bool isExchange = false,
    bool showPhone = true,
    required List<File> images,
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/annonces'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['categoryId'] = categoryId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['state'] = state.toString();
    request.fields['isExchange'] = isExchange.toString();
    request.fields['showPhone'] = showPhone.toString();
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return AnnonceDetail.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Erreur lors de la création de l\'annonce');
    }
  }

  Future<List<MyAnnonce>> getMyAnnonces() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/annonces/my'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((item) => MyAnnonce.fromJson(item)).toList();
    } else {
      throw Exception('Erreur lors de la récupération de vos annonces');
    }
  }

  Future<void> deleteAnnonce(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/annonces/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de l\'annonce');
    }
  }

  // ─── Ratings endpoints ───

  Future<void> submitRating({
    required int sellerId,
    required num rating,
    String? comment,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: headers,
      body: jsonEncode({
        'sellerId': sellerId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'envoi de la note');
    }
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

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Conversation introuvable');
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

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Erreur lors de l\'envoi du message');
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
