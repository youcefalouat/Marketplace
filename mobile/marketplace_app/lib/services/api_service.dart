import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

class ApiService {
  // TODO: Update this URL for production
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;
  User? _currentUser;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

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

  // HTTP Helpers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'city': city,
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

  Future<void> logout() async {
    await clearToken();
  }

  // User endpoints
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
    required String city,
  }) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'city': city,
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

  // Annonces endpoints
  Future<PaginatedResponse<AnnonceListItem>> getAnnonces({
    int? category,
    double? minPrice,
    double? maxPrice,
    String? city,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    
    if (category != null) queryParams['category'] = category.toString();
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (city != null && city.isNotEmpty) queryParams['city'] = city;

    final uri = Uri.parse('$baseUrl/annonces').replace(queryParameters: queryParams);
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

  Future<AnnonceDetail> getAnnonceDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/annonces/$id'));

    if (response.statusCode == 200) {
      return AnnonceDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Annonce non trouvée');
    }
  }

  Future<AnnonceDetail> createAnnonce({
    required int category,
    required String title,
    required String description,
    required double price,
    required int state,
    String? phone,
    String? city,
    required List<String> imagePaths,
  }) async {
    final token = await getToken();
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/annonces'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['category'] = category.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['state'] = state.toString();
    if (phone != null) request.fields['phone'] = phone;
    if (city != null) request.fields['city'] = city;

    for (final imagePath in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('images', imagePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return AnnonceDetail.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de la création de l\'annonce');
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
