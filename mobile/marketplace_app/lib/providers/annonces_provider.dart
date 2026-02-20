import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AnnoncesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AnnonceListItem> _annonces = [];
  List<MyAnnonce> _myAnnonces = [];
  AnnonceDetail? _selectedAnnonce;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  // Filters
  int? _categoryFilter;
  double? _minPrice;
  double? _maxPrice;
  int? _wilayaFilter;
  int? _communeFilter;

  // Getters
  List<AnnonceListItem> get annonces => _annonces;
  List<MyAnnonce> get myAnnonces => _myAnnonces;
  AnnonceDetail? get selectedAnnonce => _selectedAnnonce;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages;

  // Filter getters
  int? get categoryFilter => _categoryFilter;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  int? get wilayaFilter => _wilayaFilter;
  int? get communeFilter => _communeFilter;

  Future<void> loadAnnonces({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _annonces = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAnnonces(
        category: _categoryFilter,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        wilayaId: _wilayaFilter,
        communeId: _communeFilter,
        page: _currentPage,
      );

      if (refresh) {
        _annonces = response.items;
      } else {
        _annonces.addAll(response.items);
      }

      _totalPages = response.totalPages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoading) return;

    _currentPage++;
    await loadAnnonces();
  }

  void setFilters({
    int? category,
    double? minPrice,
    double? maxPrice,
    int? wilayaId,
    int? communeId,
  }) {
    _categoryFilter = category;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _wilayaFilter = wilayaId;
    _communeFilter = communeId;
    loadAnnonces(refresh: true);
  }

  void clearFilters() {
    _categoryFilter = null;
    _minPrice = null;
    _maxPrice = null;
    _wilayaFilter = null;
    _communeFilter = null;
    loadAnnonces(refresh: true);
  }

  Future<void> loadAnnonceDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedAnnonce = await _apiService.getAnnonceDetail(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyAnnonces() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myAnnonces = await _apiService.getMyAnnonces();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnonce({
    required int category,
    required String title,
    required String description,
    required double price,
    required int state,
    String? phone,
    int? wilayaId,
    int? communeId,
    bool isExchange = false,
    bool showPhone = true,
    required List<String> imagePaths,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createAnnonce(
        category: category,
        title: title,
        description: description,
        price: price,
        state: state,
        phone: phone,
        wilayaId: wilayaId,
        communeId: communeId,
        isExchange: isExchange,
        showPhone: showPhone,
        imagePaths: imagePaths,
      );
      _isLoading = false;
      notifyListeners();

      // Refresh my annonces
      await loadMyAnnonces();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAnnonce(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteAnnonce(id);
      _myAnnonces.removeWhere((a) => a.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedAnnonce() {
    _selectedAnnonce = null;
    notifyListeners();
  }
}
