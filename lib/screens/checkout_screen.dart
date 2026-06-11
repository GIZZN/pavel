import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/local_catalog_service.dart';
import '../services/orders_service.dart';
import '../models/order_model.dart';
import '../widgets/product_image.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String _delivery = 'courier'; // courier | pickup
  String _payment = 'card'; // card | cash | applepay
  bool _placing = false;

  Map<int, PropertyModel> _byId = {};
  bool _loadedCatalog = false;

  @override
  void initState() {
    super.initState();
    _initFromUser();
    _loadCatalog();
  }

  void _initFromUser() {
    final user = context.read<AuthService>().currentUser;
    if (user?.phone != null && user!.phone!.isNotEmpty) {
      final digits = user.phone!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) {
        _phoneMask.formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: digits.substring(digits.length - 10)),
        );
        _phoneController.text = _phoneMask.getMaskedText();
      }
    }
  }

  Future<void> _loadCatalog() async {
    final all = await LocalCatalogService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _byId = {for (final p in all) if (p.id != null) p.id!: p};
      _loadedCatalog = true;
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final lines = cart.items.entries
        .map((e) => MapEntry(_byId[e.key], e.value))
        .where((e) => e.key != null)
        .toList();
    final subtotal = lines.fold<double>(0, (s, e) => s + e.key!.price * e.value);
    final deliveryFee = _delivery == 'courier' && subtotal < 5000 ? 390.0 : 0.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: !_loadedCatalog
                  ? const Center(child: CircularProgressIndicator(color: ink, strokeWidth: 2))
                  : Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Доставка'),
                          const SizedBox(height: 8),
                          _buildDeliveryOptions(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Контакты'),
                          const SizedBox(height: 8),
                          _buildContactsCard(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Оплата'),
                          const SizedBox(height: 8),
                          _buildPaymentOptions(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Ваш заказ'),
                          const SizedBox(height: 8),
                          _buildItems(lines),
                          const SizedBox(height: 16),
                          _buildSummary(subtotal, deliveryFee, total),
                        ],
                      ),
                    ),
            ),
            _buildPlaceBar(total),
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
              'Оформление',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Заказ',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Доставим быстро и аккуратно',
          style: TextStyle(fontSize: 14, color: inkSoft),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: inkSoft,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        children: [
          _radioRow(
            id: 'courier',
            group: _delivery,
            icon: Icons.local_shipping_outlined,
            title: 'Курьером',
            subtitle: 'Сегодня · бесплатно от 5 000 ₽',
            onTap: () => setState(() => _delivery = 'courier'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(height: 1, color: line),
          ),
          _radioRow(
            id: 'pickup',
            group: _delivery,
            icon: Icons.store_outlined,
            title: 'В пункт выдачи',
            subtitle: 'Завтра · бесплатно',
            onTap: () => setState(() => _delivery = 'pickup'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        children: [
          _radioRow(
            id: 'card',
            group: _payment,
            icon: Icons.credit_card_outlined,
            title: 'Картой онлайн',
            subtitle: 'Visa, Mastercard, МИР',
            onTap: () => setState(() => _payment = 'card'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(height: 1, color: line),
          ),
          _radioRow(
            id: 'applepay',
            group: _payment,
            icon: Icons.phone_iphone_rounded,
            title: 'Apple Pay / SberPay',
            subtitle: 'Быстрая оплата в один клик',
            onTap: () => setState(() => _payment = 'applepay'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(height: 1, color: line),
          ),
          _radioRow(
            id: 'cash',
            group: _payment,
            icon: Icons.payments_outlined,
            title: 'При получении',
            subtitle: 'Наличными или картой',
            onTap: () => setState(() => _payment = 'cash'),
          ),
        ],
      ),
    );
  }

  Widget _radioRow({
    required String id,
    required String group,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final selected = id == group;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ink,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ink : line,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsCard() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_delivery == 'courier') ...[
            _buildField(
              controller: _addressController,
              hint: 'Адрес доставки',
              icon: Icons.location_on_outlined,
              validator: (v) {
                if (_delivery == 'courier' && (v == null || v.trim().isEmpty)) {
                  return 'Укажите адрес';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildField(
            controller: _phoneController,
            hint: '+7 (___) ___-__-__',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            formatters: [_phoneMask],
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.length < 11) return 'Введите телефон';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _commentController,
            hint: 'Комментарий курьеру',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      cursorColor: ink,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: ink, fontWeight: FontWeight.w500, letterSpacing: -0.2),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: inkSoft, fontSize: 14, fontWeight: FontWeight.w400),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: Icon(icon, size: 18, color: inkSoft),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: _border(line),
        enabledBorder: _border(line),
        focusedBorder: _border(ink, width: 1.5),
        errorBorder: _border(const Color(0xFFFF3B30)),
        focusedErrorBorder: _border(const Color(0xFFFF3B30), width: 1.5),
        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFFF3B30), fontWeight: FontWeight.w500),
      ),
      validator: validator,
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildItems(List<MapEntry<PropertyModel?, int>> lines) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        children: List.generate(lines.length, (i) {
          final p = lines[i].key!;
          final qty = lines[i].value;
          final isLast = i == lines.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ProductImage(
                        url: p.imageUrl,
                        fallbackIcon: Icons.devices_outlined,
                        borderRadius: BorderRadius.circular(10),
                        background: bg,
                        iconSize: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ink,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.location} · ×$qty',
                            style: const TextStyle(fontSize: 11, color: inkSoft),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(p.price * qty),
                      style: const TextStyle(
                        fontSize: 13,
                        color: ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 80),
                  child: Container(height: 1, color: line),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSummary(double subtotal, double delivery, double total) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _summaryRow('Товары', _formatPrice(subtotal)),
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

  Widget _buildPlaceBar(double total) {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: GestureDetector(
            onTap: _placing ? null : _place,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: _placing ? line : ink,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_placing) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: surface, strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Создаём заказ...',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: surface),
                    ),
                  ] else ...[
                    const Text(
                      'Подтвердить заказ',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _place() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final cart = context.read<CartService>();
    final orders = context.read<OrdersService>();
    final auth = context.read<AuthService>();

    // Собираем заказ
    final lines = cart.items.entries
        .map((e) => MapEntry(_byId[e.key], e.value))
        .where((e) => e.key != null)
        .toList();
    final subtotal = lines.fold<double>(0, (s, e) => s + e.key!.price * e.value);
    final deliveryFee = _delivery == 'courier' && subtotal < 5000 ? 390.0 : 0.0;
    final total = subtotal + deliveryFee;

    final orderId = 'TZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Случайное время доставки: 25–60 секунд для демо
    final seconds = 25 + (DateTime.now().millisecondsSinceEpoch % 36);
    final now = DateTime.now();
    final expectedAt = now.add(Duration(seconds: seconds));

    final order = OrderModel(
      id: orderId,
      createdAt: now,
      expectedAt: expectedAt,
      items: lines
          .map((e) => OrderItem(
                productId: e.key!.id ?? 0,
                title: e.key!.title,
                brand: e.key!.location,
                imageUrl: e.key!.imageUrl,
                price: e.key!.price,
                qty: e.value,
              ))
          .toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      paymentMethod: _payment,
      deliveryMethod: _delivery,
    );

    await orders.load(auth.currentUser?.id);
    await orders.add(order);
    await cart.clear();

    if (!mounted) return;
    setState(() => _placing = false);

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => _SuccessScreen(orderId: orderId, expectedAt: expectedAt),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
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

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.orderId, required this.expectedAt});

  final String orderId;
  final DateTime expectedAt;

  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

  String _formatExpected() {
    final diff = expectedAt.difference(DateTime.now());
    if (diff.inMinutes < 1) {
      return 'Ожидайте через ${diff.inSeconds.clamp(1, 999)} сек.';
    }
    return 'Ожидайте через ${diff.inMinutes} мин.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (r) => false,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: line, width: 1),
                    ),
                    child: const Icon(Icons.close_rounded, size: 20, color: ink),
                  ),
                ),
              ),
              const Spacer(),
              // Концентрические круги с галочкой
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: line, width: 1),
                      ),
                    ),
                    Container(
                      width: 116,
                      height: 116,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: surface,
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ink,
                      ),
                      child: const Icon(Icons.check_rounded, color: surface, size: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Заказ оформлен',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '№ $orderId',
                style: const TextStyle(
                    fontSize: 13, color: inkSoft, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                '${_formatExpected()}\nМы пришлём уведомление, когда заказ будет в пути',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: inkSoft, height: 1.5),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false,
                ),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'На главную',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: surface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
