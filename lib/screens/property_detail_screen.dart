import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/page_transition.dart';
import '../widgets/product_image.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color heart = Color(0xFFFF3B30);

  bool _isProcessingFavorite = false;

  // Категории и характеристики
  static const Map<String, String> _typeNames = {
    'phones': 'Смартфон',
    'laptops': 'Ноутбук',
    'tablets': 'Планшет',
    'audio': 'Аудио',
    'watches': 'Часы',
    'cameras': 'Камера',
    'consoles': 'Консоль',
  };

  static const Map<String, IconData> _typeIcons = {
    'phones': Icons.smartphone_outlined,
    'laptops': Icons.laptop_mac_outlined,
    'tablets': Icons.tablet_mac_outlined,
    'audio': Icons.headphones_outlined,
    'watches': Icons.watch_outlined,
    'cameras': Icons.camera_alt_outlined,
    'consoles': Icons.sports_esports_outlined,
  };

  String get _typeLabel => _typeNames[widget.property.propertyType] ?? 'Товар';
  IconData get _typeIcon => _typeIcons[widget.property.propertyType] ?? Icons.devices_outlined;

  Future<void> _toggleFavorite() async {
    if (_isProcessingFavorite) return;
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated || auth.currentUser?.id == null) {
      CustomSnackbar.info(context, 'Войдите, чтобы добавить в избранное',
          icon: Icons.login_rounded);
      return;
    }
    if (widget.property.id == null) return;

    setState(() => _isProcessingFavorite = true);
    await context.read<FavoritesService>()
        .toggleFavorite(auth.currentUser!.id!, widget.property.id!);
    if (!mounted) return;
    setState(() => _isProcessingFavorite = false);
  }

  void _addToCart() async {
    if (widget.property.id == null) return;
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    if (cart.qty(widget.property.id!) == 0) {
      await cart.load(auth.currentUser?.id);
    }
    await cart.add(widget.property.id!);
    if (!mounted) return;
    CustomSnackbar.success(context, 'Добавлено в корзину', icon: Icons.shopping_bag_outlined);
  }

  void _buyNow() async {
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) {
      Navigator.push(context,
          CircleRevealPageRoute(page: const LoginScreen(), color: ink, icon: Icons.login_rounded));
      return;
    }
    if (widget.property.id == null) return;
    final cart = context.read<CartService>();
    await cart.load(auth.currentUser?.id);
    await cart.add(widget.property.id!);
    if (!mounted) return;
    Navigator.push(context,
        CircleRevealPageRoute(page: const CartScreen(), color: ink, icon: Icons.shopping_bag_rounded));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(p),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroImage(p),
                    const SizedBox(height: 24),
                    _buildTitleBlock(p),
                    const SizedBox(height: 20),
                    _buildHighlights(p),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Описание'),
                    const SizedBox(height: 8),
                    _buildDescription(p),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Характеристики'),
                    const SizedBox(height: 8),
                    _buildSpecs(p),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Доставка и оплата'),
                    const SizedBox(height: 8),
                    _buildDelivery(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(p),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          Row(
            children: [
              _circleBtn(Icons.share_outlined, () {
                CustomSnackbar.info(context, 'Ссылка скопирована');
              }),
              const SizedBox(width: 8),
              Consumer<FavoritesService>(builder: (ctx, fav, _) {
                final isFav = widget.property.id != null && fav.isFavorite(widget.property.id!);
                return GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: line, width: 1),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? heart : ink,
                      size: 20,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: line, width: 1),
        ),
        child: Icon(icon, size: 20, color: ink),
      ),
    );
  }

  Widget _buildHeroImage(PropertyModel p) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: line, width: 1),
            ),
            child: ProductImage(
              url: p.imageUrl,
              fallbackIcon: _typeIcon,
              borderRadius: BorderRadius.circular(23),
              background: surface,
              iconSize: 96,
            ),
          ),
          if (p.isPremium)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TOP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: surface,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          // Индикаторы галереи (декоративные)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final active = i == 0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? ink : ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock(PropertyModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Бренд + тип
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_typeIcon, size: 13, color: ink),
                  const SizedBox(width: 6),
                  Text(
                    _typeLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              p.location,
              style: const TextStyle(fontSize: 12, color: inkSoft, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Заголовок
        Text(
          p.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.15,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        // Рейтинг
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 16, color: ink),
            const SizedBox(width: 4),
            const Text('4.8',
                style: TextStyle(fontSize: 14, color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text('(${120 + (p.id ?? 0) % 380} отзывов)',
                style: const TextStyle(fontSize: 13, color: inkSoft, fontWeight: FontWeight.w400)),
            const Spacer(),
            const Icon(Icons.inventory_2_outlined, size: 14, color: inkSoft),
            const SizedBox(width: 4),
            const Text('В наличии',
                style: TextStyle(fontSize: 12, color: inkSoft, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlights(PropertyModel p) {
    final items = <Map<String, dynamic>>[
      {'icon': Icons.local_shipping_outlined, 'label': 'Доставка', 'value': 'Сегодня'},
      {'icon': Icons.verified_user_outlined, 'label': 'Гарантия', 'value': '2 года'},
      {'icon': Icons.refresh_rounded, 'label': 'Возврат', 'value': '14 дней'},
      {'icon': Icons.percent_rounded, 'label': 'Рассрочка', 'value': '0-0-12'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: items.map((it) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(it['icon'] as IconData, size: 18, color: ink),
                ),
                const SizedBox(height: 8),
                Text(
                  it['value'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  it['label'] as String,
                  style: const TextStyle(fontSize: 10, color: inkSoft),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildDescription(PropertyModel p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Text(
        p.description,
        style: const TextStyle(fontSize: 14, color: ink, height: 1.55, letterSpacing: -0.1),
      ),
    );
  }

  Widget _buildSpecs(PropertyModel p) {
    final specs = _generateSpecs(p);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        children: List.generate(specs.length, (i) {
          final s = specs[i];
          final isLast = i == specs.length - 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          s.key,
                          style: const TextStyle(fontSize: 13, color: inkSoft, fontWeight: FontWeight.w400),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          s.value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ink,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Container(height: 1, color: line),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<MapEntry<String, String>> _generateSpecs(PropertyModel p) {
    final base = <MapEntry<String, String>>[
      MapEntry('Категория', _typeLabel),
      MapEntry('Бренд', p.location),
      MapEntry('Артикул', 'TZ-${(p.id ?? 0).toString().padLeft(5, '0')}'),
      const MapEntry('Состояние', 'Новый'),
      const MapEntry('Гарантия', '24 месяца'),
    ];

    switch (p.propertyType) {
      case 'phones':
        base.addAll(const [
          MapEntry('Память', '256 ГБ'),
          MapEntry('ОЗУ', '8 ГБ'),
          MapEntry('Диагональ экрана', '6.1"'),
          MapEntry('Камера', '48 Мп'),
        ]);
        break;
      case 'laptops':
        base.addAll(const [
          MapEntry('Процессор', 'Apple M3 / Intel i7'),
          MapEntry('ОЗУ', '16 ГБ'),
          MapEntry('Накопитель', 'SSD 512 ГБ'),
          MapEntry('Диагональ', '14"'),
        ]);
        break;
      case 'tablets':
        base.addAll(const [
          MapEntry('Память', '256 ГБ'),
          MapEntry('Диагональ', '11"'),
          MapEntry('Связь', 'Wi-Fi + 5G'),
        ]);
        break;
      case 'audio':
        base.addAll(const [
          MapEntry('Тип', 'Беспроводные'),
          MapEntry('Шумоподавление', 'Активное'),
          MapEntry('Время работы', 'до 30 ч'),
          MapEntry('Разъём зарядки', 'USB-C'),
        ]);
        break;
      case 'watches':
        base.addAll(const [
          MapEntry('Корпус', 'Алюминий'),
          MapEntry('Размер', '45 мм'),
          MapEntry('Водозащита', '50 м'),
          MapEntry('GPS', 'Встроенный'),
        ]);
        break;
      case 'cameras':
        base.addAll(const [
          MapEntry('Матрица', 'Полный кадр'),
          MapEntry('Разрешение', '24-40 Мп'),
          MapEntry('Видео', '4K 60p'),
          MapEntry('Стабилизация', 'IBIS 5 stops'),
        ]);
        break;
      case 'consoles':
        base.addAll(const [
          MapEntry('Память', '1 ТБ SSD'),
          MapEntry('Разрешение', '4K HDR'),
          MapEntry('Частота', 'до 120 Гц'),
        ]);
        break;
    }
    return base;
  }

  Widget _buildDelivery() {
    final items = [
      {'icon': Icons.local_shipping_outlined, 'title': 'Курьером сегодня', 'sub': 'Бесплатно от 5 000 ₽'},
      {'icon': Icons.store_outlined, 'title': 'В пункт выдачи', 'sub': 'Завтра, более 8 000 точек'},
      {'icon': Icons.credit_card_outlined, 'title': 'Оплата картой', 'sub': 'Visa, Mastercard, МИР'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final it = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
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
                      child: Icon(it['icon'] as IconData, size: 18, color: ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ink,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            it['sub'] as String,
                            style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Container(height: 1, color: line),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(PropertyModel p) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Цена',
                    style: TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(p.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    'или ${_formatPrice(p.price / 12)}/мес',
                    style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _addToCart,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: line),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: ink, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _buyNow,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Купить',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: surface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: surface),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
