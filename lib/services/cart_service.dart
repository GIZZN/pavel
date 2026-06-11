import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

/// Корзина с гибридным хранением:
/// - авторизованный пользователь → таблица `cart_items` в БД
/// - гость → SharedPreferences (ключ `cart_guest`)
/// In-memory кэш для мгновенного отображения.
class CartService extends ChangeNotifier {
  final Map<int, int> _items = {}; // productId -> qty
  int? _currentUserId;

  Map<int, int> get items => Map.unmodifiable(_items);
  int get count => _items.values.fold(0, (a, b) => a + b);
  int get uniqueCount => _items.length;
  int qty(int productId) => _items[productId] ?? 0;
  bool contains(int productId) => _items.containsKey(productId);

  String _guestKey() => 'cart_guest';

  Future<void> load(int? userId) async {
    _currentUserId = userId;
    _items.clear();

    if (userId != null) {
      // Из БД
      final fromDb = await DatabaseService.instance.getCartItems(userId);
      _items.addAll(fromDb);
      // Если в БД пусто, но есть гостевая корзина — мигрируем её
      if (_items.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getStringList(_guestKey()) ?? const [];
        if (raw.isNotEmpty) {
          for (final entry in raw) {
            final parts = entry.split(':');
            if (parts.length != 2) continue;
            final id = int.tryParse(parts[0]);
            final q = int.tryParse(parts[1]);
            if (id != null && q != null && q > 0) {
              _items[id] = q;
              await DatabaseService.instance.upsertCartItem(userId, id, q);
            }
          }
          await prefs.remove(_guestKey());
        }
      }
    } else {
      // Гость → prefs
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_guestKey()) ?? const [];
      for (final entry in raw) {
        final parts = entry.split(':');
        if (parts.length != 2) continue;
        final id = int.tryParse(parts[0]);
        final q = int.tryParse(parts[1]);
        if (id != null && q != null && q > 0) _items[id] = q;
      }
    }
    notifyListeners();
  }

  Future<void> add(int productId, {int delta = 1}) async {
    final next = ((_items[productId] ?? 0) + delta).clamp(1, 99);
    _items[productId] = next;
    notifyListeners();
    await _persistItem(productId, next);
  }

  Future<void> setQty(int productId, int qty) async {
    if (qty <= 0) {
      _items.remove(productId);
      notifyListeners();
      await _removeItem(productId);
    } else {
      _items[productId] = qty;
      notifyListeners();
      await _persistItem(productId, qty);
    }
  }

  Future<void> remove(int productId) async {
    _items.remove(productId);
    notifyListeners();
    await _removeItem(productId);
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    if (_currentUserId != null) {
      await DatabaseService.instance.clearCart(_currentUserId!);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestKey());
    }
  }

  Future<void> _persistItem(int productId, int qty) async {
    if (_currentUserId != null) {
      await DatabaseService.instance.upsertCartItem(_currentUserId!, productId, qty);
    } else {
      await _persistGuest();
    }
  }

  Future<void> _removeItem(int productId) async {
    if (_currentUserId != null) {
      await DatabaseService.instance.removeCartItem(_currentUserId!, productId);
    } else {
      await _persistGuest();
    }
  }

  Future<void> _persistGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_guestKey(), raw);
  }
}
