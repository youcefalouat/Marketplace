import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class BlockedUsersProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Set<int> _blockedUserIds = <int>{};
  int? _loadedForUser;

  Set<int> get blockedUserIds => Set.unmodifiable(_blockedUserIds);

  Future<void> load() async {
    try {
      _blockedUserIds
        ..clear()
        ..addAll(await _apiService.getBlockedUserIds());
      notifyListeners();
    } catch (_) {}
  }

  void setSession(int? userId) {
    if (_loadedForUser == userId) return;
    _loadedForUser = userId;
    _blockedUserIds.clear();
    notifyListeners();
    if (userId != null) load();
  }

  void add(int userId) {
    if (_blockedUserIds.add(userId)) notifyListeners();
  }
}
