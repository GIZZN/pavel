import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранилище избранного на SharedPreferences.
/// Сигнатура методов сохранена для совместимости с экранами:
/// `loadFavorites(userId)`, `toggleFavorite(userId, productId)`, `isFavorite(id)`, `clear()`.
/// Параметр userId влияет только на ключ в хранилище — для каждого пользователя свой список.
class FavoritesService extends ChangeNotifier {
  Set<int> _favoriteIds = {};
  int? _currentUserId;

  Set<int> get favoriteIds => _favoriteIds;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  String _key(int userId) => 'fav_ids_$userId';

  Future<void> loadFavorites(int userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? const [];
    _favoriteIds = raw.map(int.tryParse).whereType<int>().toSet();
    notifyListeners();
  }

  Future<void> toggleFavorite(int userId, int productId) async {
    _currentUserId = userId;
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(_currentUserId!),
      _favoriteIds.map((e) => e.toString()).toList(),
    );
  }

  void clear() {
    _favoriteIds.clear();
    notifyListeners();
  }
}
