import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';
import '../models/property_model.dart';
import '../services/local_catalog_service.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../widgets/page_transition.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/product_image.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/image_helper.dart';
import 'property_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class AllPropertiesScreen extends StatefulWidget {
  const AllPropertiesScreen({super.key});

  @override
  State<AllPropertiesScreen> createState() => _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends State<AllPropertiesScreen> {
  List<PropertyModel> _allProducts = [];
  List<PropertyModel> _filtered = [];
  bool _isLoading = true;
  String _selectedCategory = 'Все';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedBottomNav = 1;
  String _sortBy = 'default';
  bool _gridMode = true;

  Uint8List? _cachedAvatar;
  String? _cachedAvatarUrl;

  // Палитра как на главной
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

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

  final List<Map<String, String>> _sortOptions = [
    {'key': 'default', 'label': 'По новизне'},
    {'key': 'price_asc', 'label': 'Сначала дешёвые'},
    {'key': 'price_desc', 'label': 'Сначала дорогие'},
    {'key': 'popular', 'label': 'По популярности'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    if (auth.isAuthenticated && auth.currentUser?.id != null) {
      await context.read<FavoritesService>().loadFavorites(auth.currentUser!.id!);
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await LocalCatalogService.instance.getAll();
    if (!mounted) return;

    setState(() {
      _allProducts = products;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var list = List<PropertyModel>.from(_allProducts);

    // Категория
    if (_selectedCategory != 'Все') {
      final type = _categoryTypeMap[_selectedCategory];
      if (type != null) {
        list = list.where((p) => p.propertyType == type).toList();
      }
    }

    // Поиск
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
          p.title.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q)).toList();
    }

    // Сортировка
    switch (_sortBy) {
      case 'price_asc': list.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_desc': list.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'popular': list.sort((a, b) {
        if (a.isPremium == b.isPremium) return 0;
        return a.isPremium ? -1 : 1;
      }); break;
      default: list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() => _filtered = list);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                  SliverToBoxAdapter(child: _buildTitle()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildCategoryTabs()),
                  SliverToBoxAdapter(child: _buildSortBar()),
                  _isLoading
                      ? _buildSkeletonGrid()
                      : _filtered.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmpty())
                          : (_gridMode ? _buildGrid() : _buildList()),
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
          Consumer<AuthService>(
            builder: (ctx, auth, _) =>
                auth.isAuthenticated ? _buildAvatarBtn(auth) : _buildLoginBtn(),
          ),
        ],
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
        decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
        child: const Icon(Icons.person_outline_rounded, color: surface, size: 20),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Каталог',
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
            _isLoading ? 'Загрузка...' : '${_filtered.length} товаров',
            style: const TextStyle(
              fontSize: 15,
              color: inkSoft,
              fontWeight: FontWeight.w400,
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
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilters();
                },
                style: const TextStyle(fontSize: 14, color: ink, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: inkSoft, fontSize: 14, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _applyFilters();
                },
                child: const SizedBox(
                  width: 36,
                  child: Icon(Icons.close_rounded, color: inkSoft, size: 18),
                ),
              )
            else ...[
              Container(width: 1, height: 24, color: line),
              GestureDetector(
                onTap: _openFilterSheet,
                child: const SizedBox(
                  width: 48,
                  child: Icon(Icons.tune_rounded, color: ink, size: 18),
                ),
              ),
            ],
          ],
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
                _applyFilters();
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

  Widget _buildSortBar() {
    final currentSort = _sortOptions.firstWhere(
      (e) => e['key'] == _sortBy,
      orElse: () => _sortOptions.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: line, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 16, color: ink),
                  const SizedBox(width: 6),
                  Text(
                    currentSort['label']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Переключатель grid / list
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: line, width: 1),
            ),
            child: Row(
              children: [
                _viewModeBtn(Icons.grid_view_rounded, true),
                _viewModeBtn(Icons.view_agenda_outlined, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewModeBtn(IconData icon, bool gridValue) {
    final active = _gridMode == gridValue;
    return GestureDetector(
      onTap: () => setState(() => _gridMode = gridValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: active ? ink : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(icon, size: 14, color: active ? surface : ink),
      ),
    );
  }

  Widget _buildGrid() {
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
          (ctx, i) => _buildProductCard(_filtered[i]),
          childCount: _filtered.length,
        ),
      ),
    );
  }

  Widget _buildList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.separated(
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildListCard(_filtered[i]),
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
                      child: _buildFavoriteBtn(product),
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
                        GestureDetector(
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
                        ),
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

  Widget _buildListCard(PropertyModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          CircleRevealPageRoute(
              page: PropertyDetailScreen(property: product),
              color: ink,
              icon: Icons.shopping_bag_outlined)),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ProductImage(
                  url: product.imageUrl,
                  fallbackIcon: _getCategoryIcon(product.propertyType),
                  borderRadius: BorderRadius.circular(12),
                  background: bg,
                  iconSize: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (product.isPremium) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('TOP',
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: surface,
                                    letterSpacing: 1)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        const Icon(Icons.star_rounded, size: 11, color: ink),
                        const SizedBox(width: 2),
                        const Text('4.8',
                            style: TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.location,
                      style: const TextStyle(fontSize: 12, color: inkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        _buildFavoriteBtn(product, small: true),
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

  Widget _buildFavoriteBtn(PropertyModel product, {bool small = false}) {
    return Consumer<FavoritesService>(
      builder: (ctx, fav, _) {
        final isFav = product.id != null && fav.isFavorite(product.id!);
        final size = small ? 28.0 : 32.0;
        return GestureDetector(
          onTap: () async {
            final auth = context.read<AuthService>();
            if (!auth.isAuthenticated || auth.currentUser?.id == null || product.id == null) return;
            await fav.toggleFavorite(auth.currentUser!.id!, product.id!);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1),
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: ink,
              size: small ? 14 : 16,
            ),
          ),
        );
      },
    );
  }

  // ===== СКЕЛЕТ =====
  Widget _shimmerWrap({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEDED),
      highlightColor: const Color(0xFFF7F7F7),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }

  Widget _sk({double? width, double? height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    if (!_gridMode) return _buildSkeletonList();
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
          (ctx, i) => _shimmerWrap(child: _skeletonGridCard(showBadge: i.isEven)),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _skeletonGridCard({bool showBadge = false}) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Превью
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDED),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  if (showBadge)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _sk(width: 30, height: 16, radius: 6),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3E3E3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Контент
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sk(width: double.infinity, height: 11),
                  const SizedBox(height: 6),
                  _sk(width: 90, height: 11),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _sk(width: 28, height: 10),
                      const SizedBox(width: 6),
                      _sk(width: 60, height: 10),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _sk(width: 70, height: 14),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3E3E3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _shimmerWrap(child: _skeletonListCard(showBadge: i.isEven)),
      ),
    );
  }

  Widget _skeletonListCard({bool showBadge = false}) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (showBadge) ...[
                        _sk(width: 28, height: 14, radius: 4),
                        const SizedBox(width: 6),
                      ],
                      _sk(width: 50, height: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _sk(width: double.infinity, height: 13),
                  const SizedBox(height: 6),
                  _sk(width: 140, height: 11),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _sk(width: 80, height: 14),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3E3E3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
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
            'Попробуйте изменить фильтры или поиск',
            style: TextStyle(fontSize: 13, color: inkSoft),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'Все';
                _sortBy = 'default';
              });
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Сбросить фильтры',
                style: TextStyle(fontSize: 12, color: surface, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== BOTTOM SHEETS =====

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Text(
                  'Сортировка',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
                ),
              ),
              ..._sortOptions.map((opt) {
                final selected = _sortBy == opt['key'];
                return InkWell(
                  onTap: () {
                    setState(() => _sortBy = opt['key']!);
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Container(
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
                        const SizedBox(width: 14),
                        Text(
                          opt['label']!,
                          style: TextStyle(
                            fontSize: 15,
                            color: ink,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: line,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
                ),
                const SizedBox(height: 24),
                const Text('Категория',
                    style: TextStyle(fontSize: 13, color: inkSoft, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat['name'] as String);
                        _applyFilters();
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: selected ? ink : line, width: 1),
                        ),
                        child: Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? surface : ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
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
}
