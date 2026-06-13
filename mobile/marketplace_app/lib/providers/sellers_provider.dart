import 'package:flutter/foundation.dart';
import '../models/seller_models.dart';
import '../services/api_service.dart';

class SellersProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TopVerifiedUser> _topVerifiedUsers = [];
  bool _loadingTopUsers = false;
  String? _topUsersError;

  List<TopVerifiedUser> get topVerifiedUsers => _topVerifiedUsers;
  bool get loadingTopUsers => _loadingTopUsers;
  String? get topUsersError => _topUsersError;

  Future<void> loadTopVerifiedUsers({int? communeId, int? wilayaId}) async {
    if (_loadingTopUsers) return;
    _loadingTopUsers = true;
    _topUsersError = null;
    notifyListeners();

    try {
      _topVerifiedUsers = await _apiService.getTopVerifiedUsers(
        communeId: communeId,
        wilayaId: wilayaId,
      );
      _topUsersError = null;
    } catch (e) {
      _topUsersError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingTopUsers = false;
      notifyListeners();
    }
  }
}
