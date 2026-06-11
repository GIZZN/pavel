import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';
import '../widgets/page_transition.dart';
import '../widgets/product_image.dart';
import 'all_properties_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color accent = Color(0xFF00B26A);

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    context.read<OrdersService>().load(auth.currentUser?.id);
    // Перерисовываем раз в секунду чтобы прогресс шёл плавно
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersService>().orders;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: orders.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        _buildTitle(orders.length),
                        const SizedBox(height: 24),
                        ...orders.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderCard(o),
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: line, width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: ink),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Заказы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Мои заказы',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Всего $count ${_pluralOrders(count)}',
          style: const TextStyle(fontSize: 14, color: inkSoft),
        ),
      ],
    );
  }

  String _pluralOrders(int n) {
    final m = n % 10;
    final m100 = n % 100;
    if (m100 >= 11 && m100 <= 19) return 'заказов';
    if (m == 1) return 'заказ';
    if (m >= 2 && m <= 4) return 'заказа';
    return 'заказов';
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка карточки
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '№ ${order.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _statusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),
          // Превью товаров
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                for (int i = 0; i < order.items.take(4).length; i++)
                  Positioned(
                    left: i * 44.0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: surface, width: 2),
                      ),
                      child: ProductImage(
                        url: order.items[i].imageUrl,
                        fallbackIcon: Icons.devices_outlined,
                        borderRadius: BorderRadius.circular(10),
                        background: bg,
                        iconSize: 22,
                      ),
                    ),
                  ),
                if (order.items.length > 4)
                  Positioned(
                    left: 4 * 44.0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: surface, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+${order.items.length - 4}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Прогресс или итоговая инфо
          if (order.status == OrderStatus.processing ||
              order.status == OrderStatus.delivering)
            _progressBlock(order)
          else
            _summaryRow(order),
          const SizedBox(height: 12),
          // Низ — итог + меню
          Row(
            children: [
              Text(
                '${order.totalQty} ${_pluralItems(order.totalQty)}',
                style: const TextStyle(fontSize: 12, color: inkSoft),
              ),
              const Spacer(),
              Text(
                _formatPrice(order.total),
                style: const TextStyle(
                  fontSize: 16,
                  color: ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          if (order.status == OrderStatus.processing ||
              order.status == OrderStatus.delivering) ...[
            const SizedBox(height: 12),
            _cancelButton(order),
          ],
        ],
      ),
    );
  }

  String _pluralItems(int n) {
    final m = n % 10;
    final m100 = n % 100;
    if (m100 >= 11 && m100 <= 19) return 'товаров';
    if (m == 1) return 'товар';
    if (m >= 2 && m <= 4) return 'товара';
    return 'товаров';
  }

  Widget _statusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.processing:
        color = const Color(0xFFFFAA00);
        break;
      case OrderStatus.delivering:
        color = const Color(0xFF0066FF);
        break;
      case OrderStatus.delivered:
        color = accent;
        break;
      case OrderStatus.cancelled:
        color = const Color(0xFFFF3B30);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBlock(OrderModel order) {
    final now = DateTime.now();
    final total = order.expectedAt.difference(order.createdAt).inMilliseconds;
    final passed = now.difference(order.createdAt).inMilliseconds;
    final progress = total > 0 ? (passed / total).clamp(0.0, 1.0) : 1.0;
    final remaining = order.expectedAt.difference(now);
    final remainingText = remaining.isNegative
        ? 'Доставлен'
        : remaining.inMinutes >= 1
            ? 'Через ${remaining.inMinutes} мин ${remaining.inSeconds % 60} сек'
            : 'Через ${remaining.inSeconds} сек';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 13, color: inkSoft),
            const SizedBox(width: 4),
            Text(
              remainingText,
              style: const TextStyle(fontSize: 12, color: inkSoft, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Container(height: 4, color: line),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(color: ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(OrderModel order) {
    final addr = order.address.isNotEmpty ? order.address : 'Самовывоз';
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 14, color: inkSoft),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            addr,
            style: const TextStyle(fontSize: 12, color: inkSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _cancelButton(OrderModel order) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (ctx) => Dialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Отменить заказ?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  Text('Заказ № ${order.id} будет отменён.',
                      style: const TextStyle(fontSize: 13, color: inkSoft, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: line),
                            ),
                            child: const Text('Назад',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text('Отменить',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: surface)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (ok == true) {
          await context.read<OrdersService>().cancel(order.id);
        }
      },
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: line),
        ),
        child: const Text(
          'Отменить заказ',
          style: TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: line, width: 1),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface,
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    border: Border.all(color: line, width: 1),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: ink, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Заказов пока нет',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Оформите первый заказ —\nи он появится здесь',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: inkSoft, height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(context,
                CircleRevealPageRoute(
                    page: const AllPropertiesScreen(),
                    color: ink,
                    icon: Icons.grid_view_outlined)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('В каталог',
                      style: TextStyle(fontSize: 13, color: surface, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: surface),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} · $h:$m';
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)} млн ₽';
    } else if (price >= 1000) {
      final thousands = (price / 1000).toStringAsFixed(0);
      return '$thousands 000 ₽';
    }
    return '${price.toStringAsFixed(0)} ₽';
  }
}
