import 'dart:convert';

enum OrderStatus { processing, delivering, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.processing: return 'Обрабатывается';
      case OrderStatus.delivering: return 'В пути';
      case OrderStatus.delivered: return 'Доставлен';
      case OrderStatus.cancelled: return 'Отменён';
    }
  }

  String get key => name;

  static OrderStatus fromKey(String? key) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == key,
      orElse: () => OrderStatus.processing,
    );
  }
}

class OrderItem {
  final int productId;
  final String title;
  final String brand;
  final String? imageUrl;
  final double price;
  final int qty;

  OrderItem({
    required this.productId,
    required this.title,
    required this.brand,
    required this.imageUrl,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'brand': brand,
        'imageUrl': imageUrl,
        'price': price,
        'qty': qty,
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['productId'] as int,
        title: j['title'] as String,
        brand: j['brand'] as String,
        imageUrl: j['imageUrl'] as String?,
        price: (j['price'] as num).toDouble(),
        qty: j['qty'] as int,
      );
}

class OrderModel {
  final String id; // TZ-XXXXX
  final DateTime createdAt;
  final DateTime expectedAt;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String address;
  final String phone;
  final String paymentMethod;
  final String deliveryMethod;
  OrderStatus status;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.expectedAt,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    required this.deliveryMethod,
    this.status = OrderStatus.processing,
  });

  int get totalQty => items.fold(0, (s, i) => s + i.qty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'expectedAt': expectedAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'address': address,
        'phone': phone,
        'paymentMethod': paymentMethod,
        'deliveryMethod': deliveryMethod,
        'status': status.key,
      };

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        expectedAt: DateTime.parse(j['expectedAt'] as String),
        items: (j['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
        subtotal: (j['subtotal'] as num).toDouble(),
        deliveryFee: (j['deliveryFee'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        paymentMethod: j['paymentMethod'] as String? ?? '',
        deliveryMethod: j['deliveryMethod'] as String? ?? '',
        status: OrderStatusX.fromKey(j['status'] as String?),
      );

  String toJsonString() => jsonEncode(toJson());
  factory OrderModel.fromJsonString(String s) =>
      OrderModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
