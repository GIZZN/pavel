import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/local_catalog_service.dart';
import '../widgets/page_transition.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/product_image.dart';
import '../widgets/custom_snackbar.dart';
import 'all_properties_screen.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import 'property_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color danger = Color(0xFFFF3B30);

  int _selectedBottomNav = 3;
  bool _isLoading = true;
  Map<int, PropertyModel> _byId = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final all = await LocalCatalogService.instance.getAll();
    final auth = context.read<AuthService>();
    await context.read<CartService>().load(auth.currentUser?.id);
    if (!mounted) return;
    setState(() {
      _byId = {for (final p in all) if (p.id != null) p.id!: p};
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final cartItems = cart.items.entries
        .map((e) => MapEntry(_byId[e.key], e.value))
        .where((e) => e.key != null)
        .map((e) => _CartLine(product: e.key!, qty: e.value))
        .toList();

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(cart),
                Expanded(
                  child: _isLoading
                      ? _buildSkeleton()
                      : (cartItems.isEmpty ? _buildEmpty() : _buildList(cartItems)),
                ),
                if (!_isLoading && cartItems.isNotEmpty) _buildCheckoutBar(cartItems),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              selectedIndex: _selectedBottomNav,
              onItemSelected: (i) => setState(() => _selectedBottomNav = i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CartService cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          if (cart.uniqueCount > 0)
            GestureDetector(
              onTap: _confirmClear,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: line, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 16, color: ink),
                    SizedBox(width: 6),
                    Text('Очистить',
                        style: TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
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
              const Text(
                'Очистить корзину?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Все товары будут удалены из корзины.',
                style: TextStyle(fontSize: 13, color: inkSoft, height: 1.4),
              ),
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
                        child: const Text('Отмена',
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
                          color: danger,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('Очистить',
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
      await context.read<CartService>().clear();
    }
  }

  Widget _buildList(List<_CartLine> items) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 220),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Корзина',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: ink,
                height: 1,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${items.length} ${_pluralItems(items.length)}',
              style: const TextStyle(fontSize: 15, color: inkSoft, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...List.generate(items.length, (i) => Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
              child: _buildLineCard(items[i]),
            )),
        const SizedBox(height: 20),
        _buildPromoCode(),
        const SizedBox(height: 16),
        _buildSummary(items),
      ],
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

  Widget _buildLineCard(_CartLine entry) {
    final p = entry.product;
    return Dismissible(
      key: ValueKey('cart_${p.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: surface, size: 20),
      ),
      onDismissed: (_) => context.read<CartService>().remove(p.id!),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            CircleRevealPageRoute(
                page: PropertyDetailScreen(property: p),
                color: ink,
                icon: Icons.shopping_bag_outlined)),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line, width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ProductImage(
                  url: p.imageUrl,
                  fallbackIcon: Icons.devices_outlined,
                  borderRadius: BorderRadius.circular(12),
                  background: bg,
                  iconSize: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ink,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.location,
                      style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(p.price * entry.qty),
                          style: const TextStyle(
                            fontSize: 14,
                            color: ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        _qtyControl(p.id!, entry.qty),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyControl(int productId, int qty) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => context.read<CartService>().setQty(productId, qty - 1),
            child: const SizedBox(
              width: 28,
              height: 30,
              child: Icon(Icons.remove_rounded, size: 14, color: ink),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<CartService>().setQty(productId, qty + 1),
            child: const SizedBox(
              width: 28,
              height: 30,
              child: Icon(Icons.add_rounded, size: 14, color: ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCode() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, size: 18, color: inkSoft),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Промокод',
                style: TextStyle(color: inkSoft, fontSize: 14, fontWeight: FontWeight.w400)),
          ),
          GestureDetector(
            onTap: () => CustomSnackbar.info(context, 'Промокод применён'),
            child: const Text('Применить',
                style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<_CartLine> items) {
    final subtotal = items.fold<double>(0, (s, l) => s + l.product.price * l.qty);
    const delivery = 0.0;
    final total = subtotal + delivery;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _summaryRow('Товары (${items.length})', _formatPrice(subtotal)),
          const SizedBox(height: 8),
          _summaryRow('Доставка', delivery == 0 ? 'Бесплатно' : _formatPrice(delivery)),
          const SizedBox(height: 12),
          Container(height: 1, color: line),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Итого',
                  style: TextStyle(fontSize: 14, color: ink, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                _formatPrice(total),
                style: const TextStyle(
                  fontSize: 18,
                  color: ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: inkSoft, fontWeight: FontWeight.w400)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
      ],
    );
  }

  Widget _buildCheckoutBar(List<_CartLine> items) {
    final total = items.fold<double>(0, (s, l) => s + l.product.price * l.qty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      child: GestureDetector(
        onTap: () => _checkout(),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Оформить заказ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: surface,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                _formatPrice(total),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: surface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: surface),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) {
      Navigator.push(context,
          CircleRevealPageRoute(page: const LoginScreen(), color: ink, icon: Icons.login_rounded));
      return;
    }
    Navigator.push(context,
        CircleRevealPageRoute(
            page: const CheckoutScreen(),
            color: ink,
            icon: Icons.check_rounded));
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Декоративная иллюстрация: концентрические круги + сумка
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
                  child: const Icon(Icons.shopping_bag_outlined, color: ink, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Корзина пуста',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Добавьте товары из каталога,\nчтобы оформить заказ',
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

  Widget _buildSkeleton() {
    Widget shim({required Widget child}) => Shimmer.fromColors(
          baseColor: const Color(0xFFEDEDED),
          highlightColor: const Color(0xFFF7F7F7),
          period: const Duration(milliseconds: 1400),
          child: child,
        );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        shim(child: Container(width: 200, height: 40, decoration: BoxDecoration(color: const Color(0xFFEDEDED), borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 32),
        ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: shim(
                child: Container(
                  height: 104,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: line, width: 1),
                  ),
                ),
              ),
            )),
      ],
    );
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

class _CartLine {
  final PropertyModel product;
  final int qty;
  _CartLine({required this.product, required this.qty});
}
