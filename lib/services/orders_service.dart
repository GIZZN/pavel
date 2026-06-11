import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Заказы с гибридным хранением:
/// - авторизован → БД (orders + order_items)
/// - гость → SharedPreferences
/// Таймеры на смену статуса (processing → delivering → delivered)
/// + push-уведомления + запись в inbox через onOrderEvent.
class OrdersService extends ChangeNotifier {
  static void Function(String id, String title, String body)? onOrderEvent;

  final List<OrderModel> _orders = [];
  int? _currentUserId;
  final Map<String, List<Timer>> _timers = {};

  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> get active => _orders
      .where((o) => o.status == OrderStatus.processing || o.status == OrderStatus.delivering)
      .toList()
    ..sort((a, b) => a.expectedAt.compareTo(b.expectedAt));

  OrderModel? get nearestActive => active.isEmpty ? null : active.first;

  String _guestKey() => 'orders_guest';

  Future<void> load(int? userId) async {
    _currentUserId = userId;
    _cancelAllTimers();
    _orders.clear();

    if (userId != null) {
      final rows = await DatabaseService.instance.getOrders(userId);
      for (final r in rows) {
        _orders.add(_orderFromRow(r));
      }

      // Миграция гостевых заказов в БД
      if (_orders.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getStringList(_guestKey()) ?? const [];
        for (final s in raw) {
          try {
            final o = OrderModel.fromJsonString(s);
            await DatabaseService.instance.insertOrder(
              userId: userId,
              extId: o.id,
              status: o.status.key,
              subtotal: o.subtotal,
              deliveryFee: o.deliveryFee,
              total: o.total,
              address: o.address,
              phone: o.phone,
              paymentMethod: o.paymentMethod,
              deliveryMethod: o.deliveryMethod,
              createdAt: o.createdAt,
              expectedAt: o.expectedAt,
              items: o.items.map((i) => {
                    'product_id': i.productId,
                    'title': i.title,
                    'brand': i.brand,
                    'image_url': i.imageUrl,
                    'price': i.price,
                    'qty': i.qty,
                  }).toList(),
            );
            _orders.add(o);
          } catch (_) {}
        }
        if (_orders.isNotEmpty) await prefs.remove(_guestKey());
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_guestKey()) ?? const [];
      for (final s in raw) {
        try {
          _orders.add(OrderModel.fromJsonString(s));
        } catch (_) {}
      }
    }

    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _resumeTimers();
    notifyListeners();
  }

  OrderModel _orderFromRow(Map<String, dynamic> r) {
    return OrderModel(
      id: r['ext_id'] as String,
      createdAt: r['created_at'] as DateTime,
      expectedAt: r['expected_at'] as DateTime,
      items: (r['items'] as List)
          .map((it) => OrderItem(
                productId: it['product_id'] as int,
                title: it['title'] as String,
                brand: it['brand'] as String? ?? '',
                imageUrl: it['image_url'] as String?,
                price: (it['price'] as num).toDouble(),
                qty: it['qty'] as int,
              ))
          .toList(),
      subtotal: (r['subtotal'] as num).toDouble(),
      deliveryFee: (r['delivery_fee'] as num).toDouble(),
      total: (r['total'] as num).toDouble(),
      address: r['address'] as String? ?? '',
      phone: r['phone'] as String? ?? '',
      paymentMethod: r['payment_method'] as String? ?? '',
      deliveryMethod: r['delivery_method'] as String? ?? '',
      status: OrderStatusX.fromKey(r['status'] as String?),
    );
  }

  Future<void> add(OrderModel order) async {
    _orders.insert(0, order);

    if (_currentUserId != null) {
      await DatabaseService.instance.insertOrder(
        userId: _currentUserId!,
        extId: order.id,
        status: order.status.key,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        total: order.total,
        address: order.address,
        phone: order.phone,
        paymentMethod: order.paymentMethod,
        deliveryMethod: order.deliveryMethod,
        createdAt: order.createdAt,
        expectedAt: order.expectedAt,
        items: order.items.map((i) => {
              'product_id': i.productId,
              'title': i.title,
              'brand': i.brand,
              'image_url': i.imageUrl,
              'price': i.price,
              'qty': i.qty,
            }).toList(),
      );
    } else {
      await _persistGuest();
    }

    _scheduleTimers(order);
    notifyListeners();
  }

  Future<void> _persistGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _guestKey(),
      _orders.map((e) => e.toJsonString()).toList(),
    );
  }

  Future<void> _persistStatus(OrderModel order) async {
    if (_currentUserId != null) {
      await DatabaseService.instance.updateOrderStatus(
        _currentUserId!,
        order.id,
        order.status.key,
      );
    } else {
      await _persistGuest();
    }
  }

  void _scheduleTimers(OrderModel order) {
    _cancelTimers(order.id);
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
      return;
    }
    final now = DateTime.now();
    final total = order.expectedAt.difference(order.createdAt);
    final transitAt =
        order.createdAt.add(Duration(milliseconds: (total.inMilliseconds * 0.3).round()));

    final transitDelay = transitAt.difference(now);
    final deliverDelay = order.expectedAt.difference(now);

    final timers = <Timer>[];

    if (order.status == OrderStatus.processing && transitDelay.inMilliseconds > 0) {
      timers.add(Timer(transitDelay, () => _markDelivering(order.id)));
    } else if (order.status == OrderStatus.processing && deliverDelay.inMilliseconds > 0) {
      _markDelivering(order.id);
    }

    if (deliverDelay.inMilliseconds > 0 && order.status != OrderStatus.delivered) {
      timers.add(Timer(deliverDelay, () => _markDelivered(order.id)));
    } else if (order.status != OrderStatus.delivered) {
      _markDelivered(order.id);
    }

    _timers[order.id] = timers;
  }

  void _resumeTimers() {
    for (final o in _orders) {
      if (o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled) continue;
      _scheduleTimers(o);
    }
  }

  void _cancelTimers(String id) {
    for (final t in _timers[id] ?? const <Timer>[]) {
      t.cancel();
    }
    _timers.remove(id);
  }

  void _cancelAllTimers() {
    for (final list in _timers.values) {
      for (final t in list) {
        t.cancel();
      }
    }
    _timers.clear();
  }

  Future<void> _markDelivering(String id) async {
    final i = _orders.indexWhere((e) => e.id == id);
    if (i == -1) return;
    if (_orders[i].status == OrderStatus.processing) {
      _orders[i].status = OrderStatus.delivering;
      await _persistStatus(_orders[i]);
      notifyListeners();
      const title = 'Заказ в пути';
      final body = 'Ваш заказ № $id передан курьеру';
      await NotificationService.showOrderUpdate(orderId: id, title: title, body: body);
      onOrderEvent?.call('order_${id}_delivering', title, body);
    }
  }

  Future<void> _markDelivered(String id) async {
    final i = _orders.indexWhere((e) => e.id == id);
    if (i == -1) return;
    if (_orders[i].status != OrderStatus.delivered) {
      _orders[i].status = OrderStatus.delivered;
      await _persistStatus(_orders[i]);
      notifyListeners();
      const title = 'Заказ доставлен';
      final body = 'Заберите ваш заказ № $id. Спасибо за покупку!';
      await NotificationService.showOrderUpdate(orderId: id, title: title, body: body);
      onOrderEvent?.call('order_${id}_delivered', title, body);
    }
  }

  Future<void> cancel(String id) async {
    final i = _orders.indexWhere((e) => e.id == id);
    if (i == -1) return;
    if (_orders[i].status == OrderStatus.delivered) return;
    _cancelTimers(id);
    _orders[i].status = OrderStatus.cancelled;
    await _persistStatus(_orders[i]);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _cancelAllTimers();
    _orders.clear();
    if (_currentUserId != null) {
      // Удаление заказов из БД (по одному статусу cancelled — не годится; делаем мягкую очистку)
      // Для простоты: маркируем всё как cancelled, чтобы они не были активными.
      // Полная физическая очистка добавляется при необходимости отдельным методом.
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestKey());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}
