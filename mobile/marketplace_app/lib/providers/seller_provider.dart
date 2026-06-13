import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/seller_models.dart';
import '../services/api_service.dart';

class SellerShowcaseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  SellerProfile? _profile;
  bool _loadingProfile = false;
  String? _profileError;

  List<AnnonceListItem> _annonces = [];
  bool _loadingAnnonces = false;
  bool _loadingMoreAnnonces = false;
  int _annoncesPage = 1;
  int _annoncesTotalPages = 1;

  List<SellerReview> _reviews = [];
  bool _loadingReviews = false;
  bool _loadingMoreReviews = false;
  int _reviewsPage = 1;
  int _reviewsTotalPages = 1;

  SellerProfile? get profile => _profile;
  bool get loadingProfile => _loadingProfile;
  String? get profileError => _profileError;

  List<AnnonceListItem> get annonces => _annonces;
  bool get loadingAnnonces => _loadingAnnonces;
  bool get loadingMoreAnnonces => _loadingMoreAnnonces;
  bool get hasMoreAnnonces => _annoncesPage < _annoncesTotalPages;

  List<SellerReview> get reviews => _reviews;
  bool get loadingReviews => _loadingReviews;
  bool get loadingMoreReviews => _loadingMoreReviews;
  bool get hasMoreReviews => _reviewsPage < _reviewsTotalPages;

  Future<void> loadProfile(int sellerId) async {
    _loadingProfile = true;
    _profileError = null;
    _annonces = [];
    _reviews = [];
    _annoncesPage = 1;
    _reviewsPage = 1;
    notifyListeners();

    try {
      _profile = await _apiService.getSellerProfile(sellerId);
      _profileError = null;
    } catch (e) {
      _profileError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadAnnonces(int sellerId, {bool refresh = false}) async {
    if (refresh) {
      _annonces = [];
      _annoncesPage = 1;
    }
    if (_loadingAnnonces) return;
    _loadingAnnonces = true;
    notifyListeners();

    try {
      final response = await _apiService.getSellerAnnonces(sellerId, page: _annoncesPage);
      _annonces = [..._annonces, ...response.items];
      _annoncesTotalPages = response.totalPages;
      _annoncesPage++;
    } catch (_) {
      // silently fail — list stays as-is
    } finally {
      _loadingAnnonces = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreAnnonces(int sellerId) async {
    if (_loadingMoreAnnonces || !hasMoreAnnonces) return;
    _loadingMoreAnnonces = true;
    notifyListeners();

    try {
      final response = await _apiService.getSellerAnnonces(sellerId, page: _annoncesPage);
      _annonces = [..._annonces, ...response.items];
      _annoncesTotalPages = response.totalPages;
      _annoncesPage++;
    } catch (_) {
      // silently fail
    } finally {
      _loadingMoreAnnonces = false;
      notifyListeners();
    }
  }

  Future<void> loadReviews(int sellerId, {bool refresh = false}) async {
    if (refresh) {
      _reviews = [];
      _reviewsPage = 1;
    }
    if (_loadingReviews) return;
    _loadingReviews = true;
    notifyListeners();

    try {
      final response = await _apiService.getSellerReviews(sellerId, page: _reviewsPage);
      _reviews = [..._reviews, ...response.items];
      _reviewsTotalPages = response.totalPages;
      _reviewsPage++;
    } catch (_) {
      // silently fail
    } finally {
      _loadingReviews = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReviews(int sellerId) async {
    if (_loadingMoreReviews || !hasMoreReviews) return;
    _loadingMoreReviews = true;
    notifyListeners();

    try {
      final response = await _apiService.getSellerReviews(sellerId, page: _reviewsPage);
      _reviews = [..._reviews, ...response.items];
      _reviewsTotalPages = response.totalPages;
      _reviewsPage++;
    } catch (_) {
      // silently fail
    } finally {
      _loadingMoreReviews = false;
      notifyListeners();
    }
  }
}
