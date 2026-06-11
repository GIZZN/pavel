import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';
import '../services/local_catalog_service.dart';
import '../services/orders_service.dart';
import '../services/inbox_service.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../models/property_model.dart';
import '../models/order_model.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/page_transition.dart';
import '../widgets/product_image.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/image_helper.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'orders_screen.dart';
import 'notifications_screen.dart';
import 'all_properties_screen.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'Все';
  int _selectedBottomNav = 0;
  List<PropertyModel> _allProducts = [];
  List<PropertyModel> _filteredProducts = [];
  bool _isLoading = true;
  Uint8List? _cachedAvatar;
  String? _cachedAvatarUrl;

  // Таймер для флэш-распродажи
  Timer? _saleTimer;
  Duration _saleRemaining = const Duration(hours: 5, minutes: 23, seconds: 47);

  // Минималистичная палитра
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color accent = Color(0xFFFF3B30);

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Все', 'icon': Icons.grid_view_outlined},
    {'name': 'Смартфоны', 'icon': Icons.smartphone_outlined},
    {'name': 'Ноутбуки', 'icon': Icons.laptop_mac_outlined},
    {'name': 'Планшеты', 'icon': Icons.tablet_mac_outlined},
    {'name': 'Аудио', 'icon': Icons.headphones_outlined},
    {'name': 'Часы', 'icon': Icons.watch_outlined},
    {'name': 'Камеры', 'icon': Icons.camera_alt_outlined},
    {'name': 'Консоли', 'icon': Icons.sports_esports_outlined},
  ];

  final Map<String, String> _categoryTypeMap = {
    'Смартфоны': LocalCatalogService.catPhones,
    'Ноутбуки': LocalCatalogService.catLaptops,
    'Планшеты': LocalCatalogService.catTablets,
    'Аудио': LocalCatalogService.catAudio,
    'Часы': LocalCatalogService.catWatches,
    'Камеры': LocalCatalogService.catCameras,
    'Консоли': LocalCatalogService.catConsoles,
  };

  // Бренды
  final List<Map<String, String>> _brands = [
    {'name': 'Apple', 'logo': ''},
    {'name': 'Samsung', 'logo': 'S'},
    {'name': 'Sony', 'logo': 'S'},
    {'name': 'Xiaomi', 'logo': 'M'},
    {'name': 'Asus', 'logo': 'A'},
    {'name': 'JBL', 'logo': 'J'},
    {'name': 'Huawei', 'logo': 'H'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _saleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_saleRemaining.inSeconds > 0) {
          _saleRemaining = _saleRemaining - const Duration(seconds: 1);
        }
      });
    });
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await LocalCatalogService.instance.getAll();
    if (!mounted) return;

    // Подгружаем заказы текущего пользователя (для виджета "Активный заказ")
    final auth = context.read<AuthService>();
    await context.read<OrdersService>().load(auth.currentUser?.id);
    if (!mounted) return;

    setState(() {
      _allProducts = products;
      _filterProducts();
      _isLoading = false;
    });
  }

  void _filterProducts() {
    if (_selectedCategory == 'Все') {
      _filteredProducts = _allProducts;
    } else {
      final type = _categoryTypeMap[_selectedCategory];
      _filteredProducts = type != null
          ? _allProducts.where((p) => p.propertyType == type).toList()
          : _allProducts;
    }
  }

  @override
  void dispose() {
    _saleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: ink,
              backgroundColor: surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildActiveOrder()),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  SliverToBoxAdapter(child: _buildCategoryTabs()),
                  SliverToBoxAdapter(child: _buildFlashSale()),
                  SliverToBoxAdapter(child: _buildBrands()),
                  SliverToBoxAdapter(child: _buildFeatured()),
                  SliverToBoxAdapter(child: _buildProductsHeader()),
                  _isLoading
                      ? _buildSkeletonGrid()
                      : _filteredProducts.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmpty())
                          : _buildProductsGrid(),
                  SliverToBoxAdapter(child: _buildPromoBanner()),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 13,
                  color: inkSoft,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Consumer<AuthService>(
                builder: (ctx, auth, _) => Text(
                  auth.isAuthenticated ? (auth.currentUser?.name.split(' ').first ?? 'Гость') : 'Гость',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Consumer<InboxService>(builder: (ctx, inbox, _) {
                return _iconBtn(
                  Icons.notifications_none_rounded,
                  hasDot: inbox.unreadCount > 0,
                  onTap: () => Navigator.push(
                    context,
                    CircleRevealPageRoute(
                        page: const NotificationsScreen(),
                        color: ink,
                        icon: Icons.notifications_none_rounded),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Consumer<AuthService>(
                builder: (ctx, auth, _) {
                  return auth.isAuthenticated ? _buildAvatarBtn(auth) : _buildLoginBtn();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  Widget _iconBtn(IconData icon, {bool hasDot = false, required VoidCallback onTap}) {
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
        child: Stack(
          children: [
            Center(child: Icon(icon, color: ink, size: 20)),
            if (hasDot)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarBtn(AuthService auth) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          CircleRevealPageRoute(page: const ProfileScreen(), color: ink, icon: Icons.person_outline_rounded)),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: line, width: 1),
        ),
        child: ClipOval(
          child: auth.currentUser?.avatarUrl != null && auth.currentUser!.avatarUrl!.isNotEmpty
              ? Builder(builder: (ctx) {
                  if (_cachedAvatarUrl != auth.currentUser!.avatarUrl) {
                    _cachedAvatarUrl = auth.currentUser!.avatarUrl;
                    _cachedAvatar = ImageHelper.safeBase64Decode(auth.currentUser!.avatarUrl);
                  }
                  return _cachedAvatar != null
                      ? Image.memory(_cachedAvatar!, fit: BoxFit.cover)
                      : const Icon(Icons.person_outline_rounded, color: ink, size: 20);
                })
              : const Icon(Icons.person_outline_rounded, color: ink, size: 20),
        ),
      ),
    );
  }

  Widget _buildLoginBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          CircleRevealPageRoute(page: const LoginScreen(), color: ink, icon: Icons.login_rounded)),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: ink,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_outline_rounded, color: surface, size: 20),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Магазин',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'техники',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              color: inkSoft,
              height: 1,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: line, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search_rounded, color: inkSoft, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Поиск',
                style: TextStyle(color: inkSoft, fontSize: 14, fontWeight: FontWeight.w400),
              ),
            ),
            Container(width: 1, height: 24, color: line),
            const SizedBox(
              width: 48,
              child: Icon(Icons.tune_rounded, color: ink, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.local_shipping_outlined, 'label': 'Доставка', 'sub': 'Сегодня'},
      {'icon': Icons.refresh_rounded, 'label': 'Возврат', 'sub': '14 дней'},
      {'icon': Icons.verified_outlined, 'label': 'Гарантия', 'sub': '2 года'},
      {'icon': Icons.percent_rounded, 'label': 'Рассрочка', 'sub': '0-0-12'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: List.generate(actions.length, (i) {
              final a = actions[i];
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a['icon'] as IconData, size: 18, color: ink),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['label'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      a['sub'] as String,
                      style: const TextStyle(fontSize: 10, color: inkSoft),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length,
          itemBuilder: (ctx, i) {
            final cat = _categories[i];
            final isSelected = _selectedCategory == cat['name'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = cat['name'] as String;
                _filterProducts();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? ink : line,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? surface : ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlashSale() {
    if (_isLoading) return const SizedBox.shrink();
    final saleProducts = _allProducts.take(5).toList();
    if (saleProducts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Flash Sale',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildCountdown(),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Скидки до 40%',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Только сегодня. Успей купить.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: saleProducts.length,
                  itemBuilder: (ctx, i) {
                    final p = saleProducts[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          CircleRevealPageRoute(
                              page: PropertyDetailScreen(property: p),
                              color: ink,
                              icon: Icons.shopping_bag_outlined)),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ProductImage(
                                url: p.imageUrl,
                                fallbackIcon: _getCategoryIcon(p.propertyType),
                                borderRadius: BorderRadius.circular(13),
                                background: Colors.white.withValues(alpha: 0.04),
                                iconColor: Colors.white,
                                iconSize: 32,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '-40%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_saleRemaining.inHours);
    final m = two(_saleRemaining.inMinutes.remainder(60));
    final s = two(_saleRemaining.inSeconds.remainder(60));

    Widget cell(String v) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            v,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        );

    return Row(
      children: [
        cell(h),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(':',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        cell(m),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(':',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        cell(s),
      ],
    );
  }

  Widget _buildBrands() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Бренды',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ink,
                letterSpacing: -0.4,
              ),
            ),
          ),
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: _brands.length,
              itemBuilder: (ctx, i) {
                final b = _brands[i];
                return Container(
                  width: 76,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: line, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      b['name']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatured() {
    if (_isLoading) return const SizedBox.shrink();
    final featured = _allProducts.where((p) => p.isPremium).take(3).toList();
    if (featured.isEmpty) {
      final fallback = _allProducts.take(3).toList();
      if (fallback.isEmpty) return const SizedBox.shrink();
      return _buildFeaturedList(fallback);
    }
    return _buildFeaturedList(featured);
  }

  Widget _buildFeaturedList(List<PropertyModel> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Рекомендуем',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const Text(
                  'Смотреть все',
                  style: TextStyle(fontSize: 13, color: inkSoft, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final p = items[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      CircleRevealPageRoute(
                          page: PropertyDetailScreen(property: p),
                          color: ink,
                          icon: Icons.shopping_bag_outlined)),
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: line, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Хит',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: ink,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 12, color: ink),
                                    const SizedBox(width: 2),
                                    const Text('4.9',
                                        style: TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    Text('(${120 + p.id! % 380})',
                                        style: const TextStyle(fontSize: 11, color: inkSoft)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _formatPrice(p.price),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ProductImage(
                                url: p.imageUrl,
                                fallbackIcon: _getCategoryIcon(p.propertyType),
                                borderRadius: BorderRadius.circular(14),
                                background: bg,
                                iconSize: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Каталог',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: line),
                ),
                child: Text(
                  '${_filteredProducts.length}',
                  style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                CircleRevealPageRoute(
                    page: const AllPropertiesScreen(),
                    color: ink,
                    icon: Icons.grid_view_outlined)),
            child: const Row(
              children: [
                Text('Все',
                    style: TextStyle(fontSize: 13, color: inkSoft, fontWeight: FontWeight.w500)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16, color: inkSoft),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _buildProductCard(_filteredProducts[i]),
          childCount: _filteredProducts.length > 10 ? 10 : _filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(PropertyModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          CircleRevealPageRoute(
              page: PropertyDetailScreen(property: product),
              color: ink,
              icon: Icons.shopping_bag_outlined)),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProductImage(
                        url: product.imageUrl,
                        fallbackIcon: _getCategoryIcon(product.propertyType),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        background: bg,
                      ),
                    ),
                    if (product.isPremium)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TOP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: surface,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _favoriteButton(product),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ink,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 11, color: ink),
                        const SizedBox(width: 2),
                        const Text('4.8',
                            style: TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('· ${product.location}',
                              style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _formatPrice(product.price),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ink,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _addToCartButton(product),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteButton(PropertyModel product) {
    return Consumer<FavoritesService>(
      builder: (ctx, fav, _) {
        final isFav = product.id != null && fav.isFavorite(product.id!);
        return GestureDetector(
          onTap: () => _toggleFavorite(product),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1),
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? const Color(0xFFFF3B30) : ink,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _addToCartButton(PropertyModel product) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: ink,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: surface, size: 16),
      ),
    );
  }

  Future<void> _toggleFavorite(PropertyModel product) async {
    if (product.id == null) return;
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated || auth.currentUser?.id == null) {
      CustomSnackbar.info(context, 'Войдите, чтобы сохранить товар',
          icon: Icons.login_rounded);
      return;
    }
    await context.read<FavoritesService>()
        .toggleFavorite(auth.currentUser!.id!, product.id!);
  }

  Future<void> _addToCart(PropertyModel product) async {
    if (product.id == null) return;
    final auth = context.read<AuthService>();
    final cart = context.read<CartService>();
    if (cart.qty(product.id!) == 0) {
      await cart.load(auth.currentUser?.id);
    }
    await cart.add(product.id!);
    if (!mounted) return;
    CustomSnackbar.success(context, 'Добавлено в корзину',
        icon: Icons.shopping_bag_outlined);
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'РАССРОЧКА',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '0–0–12',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Без переплат\nна 12 месяцев',
                      style: TextStyle(
                        fontSize: 13,
                        color: inkSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Подробнее',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: surface,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: surface),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.credit_card_outlined, size: 40, color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== СКЕЛЕТЫ =====

  Widget _skeletonBox({double? width, double? height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEDED),
      highlightColor: const Color(0xFFF7F7F7),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }

  Widget _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _shimmer(
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDEDED),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _skeletonBox(width: double.infinity, height: 12),
                          const SizedBox(height: 6),
                          _skeletonBox(width: 80, height: 10),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _skeletonBox(width: 60, height: 14),
                              _skeletonBox(width: 28, height: 28, radius: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1),
            ),
            child: const Icon(Icons.search_off_rounded, size: 28, color: inkSoft),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ничего не найдено',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Попробуйте другую категорию',
            style: TextStyle(fontSize: 13, color: inkSoft),
          ),
        ],
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

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case LocalCatalogService.catPhones: return Icons.smartphone_outlined;
      case LocalCatalogService.catLaptops: return Icons.laptop_mac_outlined;
      case LocalCatalogService.catTablets: return Icons.tablet_mac_outlined;
      case LocalCatalogService.catAudio: return Icons.headphones_outlined;
      case LocalCatalogService.catWatches: return Icons.watch_outlined;
      case LocalCatalogService.catCameras: return Icons.camera_alt_outlined;
      case LocalCatalogService.catConsoles: return Icons.sports_esports_outlined;
      default: return Icons.devices_outlined;
    }
  }

  // ===== Активный заказ на главной =====
  Widget _buildActiveOrder() {
    final orders = context.watch<OrdersService>();
    final order = orders.nearestActive;
    if (order == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final total = order.expectedAt.difference(order.createdAt).inMilliseconds;
    final passed = now.difference(order.createdAt).inMilliseconds;
    final progress = total > 0 ? (passed / total).clamp(0.0, 1.0) : 1.0;
    final remaining = order.expectedAt.difference(now);
    final remainingText = remaining.isNegative
        ? 'Доставлен'
        : remaining.inMinutes >= 1
            ? '${remaining.inMinutes} мин ${remaining.inSeconds % 60} сек'
            : '${remaining.inSeconds} сек';

    final isDelivering = order.status == OrderStatus.delivering;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            CircleRevealPageRoute(
                page: const OrdersScreen(),
                color: ink,
                icon: Icons.receipt_long_outlined)),
        child: Container(
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDelivering ? Icons.local_shipping_outlined : Icons.access_time_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivering ? 'Курьер уже в пути' : 'Заказ обрабатывается',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '№ ${order.id} · ${order.totalQty} шт.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        remainingText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'до доставки',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    Container(height: 4, color: Colors.white.withValues(alpha: 0.12)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 4,
                        decoration: const BoxDecoration(color: Colors.white),
                      ),
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
}
