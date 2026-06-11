import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

enum InboxType { orderStatus, promo, system }

InboxType _typeFromKey(String? k) =>
    InboxType.values.firstWhere((e) => e.name == k, orElse: () => InboxType.system);

class InboxItem {
  final String id;
  final InboxType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
        id: j['id'] as String,
        type: _typeFromKey(j['type'] as String?),
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        read: j['read'] as bool? ?? false,
      );
}

/// In-app inbox с гибридным хранением:
/// - авторизован → таблица `inbox_notifications`
/// - гость → SharedPreferences (`inbox_guest`)
class InboxService extends ChangeNotifier {
  final List<InboxItem> _items = [];
  int? _userId;

  List<InboxItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((e) => !e.read).length;

  String _guestKey() => 'inbox_guest';

  Future<void> load(int? userId) async {
    _userId = userId;
    _items.clear();

    if (userId != null) {
      final rows = await DatabaseService.instance.getInbox(userId);
      _items.addAll(rows.map((r) => InboxItem(
            id: r['ext_id'] as String,
            type: _typeFromKey(r['type'] as String?),
            title: r['title'] as String,
            body: r['body'] as String,
            createdAt: r['created_at'] as DateTime,
            read: r['is_read'] as bool? ?? false,
          )));

      // Миграция гостевого inbox при первом логине, если в БД пусто
      if (_items.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getStringList(_guestKey()) ?? const [];
        for (final s in raw) {
          try {
            final it = InboxItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
            _items.add(it);
            await DatabaseService.instance.upsertInbox(
              userId: userId,
              extId: it.id,
              type: it.type.name,
              title: it.title,
              body: it.body,
              isRead: it.read,
              createdAt: it.createdAt,
            );
          } catch (_) {}
        }
        if (_items.isNotEmpty) await prefs.remove(_guestKey());
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_guestKey()) ?? const [];
      _items.addAll(raw.map((s) {
        try {
          return InboxItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<InboxItem>());
    }

    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Приветственное сообщение, если совсем пусто
    if (_items.isEmpty) {
      final welcome = InboxItem(
        id: 'welcome',
        type: InboxType.system,
        title: 'Добро пожаловать в Магазин техники',
        body: 'Лучшая техника по лучшим ценам. Оформите первый заказ и получите бонус.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        read: false,
      );
      _items.add(welcome);
      await _persistOne(welcome);
    }

    notifyListeners();
  }

  Future<void> push({
    required String id,
    required InboxType type,
    required String title,
    required String body,
  }) async {
    _items.removeWhere((e) => e.id == id);
    final item = InboxItem(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    _items.insert(0, item);
    notifyListeners();
    await _persistOne(item);
  }

  Future<void> markAllRead() async {
    var changed = false;
    for (final it in _items) {
      if (!it.read) {
        it.read = true;
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    if (_userId != null) {
      await DatabaseService.instance.markInboxAllRead(_userId!);
    } else {
      await _persistGuestAll();
    }
  }

  Future<void> markRead(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1 || _items[i].read) return;
    _items[i].read = true;
    notifyListeners();
    if (_userId != null) {
      await DatabaseService.instance.markInboxRead(_userId!, id);
    } else {
      await _persistGuestAll();
    }
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    if (_userId != null) {
      await DatabaseService.instance.clearInbox(_userId!);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestKey());
    }
  }

  Future<void> _persistOne(InboxItem item) async {
    if (_userId != null) {
      await DatabaseService.instance.upsertInbox(
        userId: _userId!,
        extId: item.id,
        type: item.type.name,
        title: item.title,
        body: item.body,
        isRead: item.read,
        createdAt: item.createdAt,
      );
    } else {
      await _persistGuestAll();
    }
  }

  Future<void> _persistGuestAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _guestKey(),
      _items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
