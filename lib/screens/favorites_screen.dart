import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../models/property_model.dart';
import '../services/local_catalog_service.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../widgets/page_transition.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/product_image.dart';
import '../utils/image_helper.dart';
import 'property_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<PropertyModel> _favorites = [];
  bool _isLoading = true;
  int _selectedBottomNav = 2;
  bool _gridMode = true;

  Uint8List? _cachedAvatar;
  String? _cachedAvatarUrl;

  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color heart = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavorites());
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated || auth.currentUser?.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    // Подтягиваем id-сет в FavoritesService для синхронной отметки
    await context.read<FavoritesService>().loadFavorites(auth.currentUser!.id!);
    final fav = context.read<FavoritesService>();
    final all = await LocalCatalogService.instance.getAll();
    final list = all.where((p) => p.id != null && fav.isFavorite(p.id!)).toList();
    if (!mounted) return;

    setState(() {
      _favorites = list;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(PropertyModel p) async {
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated || auth.currentUser?.id == null || p.id == null) return;
    await context.read<FavoritesService>().toggleFavorite(auth.currentUser!.id!, p.id!);
    if (!mounted) return;
    setState(() => _favorites.removeWhere((e) => e.id == p.id));
  }

  Future<void> _clearAll() async {
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
                'Очистить избранное?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Все товары будут удалены из списка.',
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
                          color: ink,
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
    if (ok != true) return;

    final auth = context.read<AuthService>();
    if (auth.currentUser?.id == null) return;
    final fav = context.read<FavoritesService>();
    final ids = _favorites.map((e) => e.id).whereType<int>().toList();
    for (final id in ids) {
      await fav.toggleFavorite(auth.currentUser!.id!, id);
    }
    if (!mounted) return;
    setState(() => _favorites.clear());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final notAuth = !auth.isAuthenticated;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: notAuth
                ? Column(
                    children: [
                      _buildHeader(showActions: false),
                      Expanded(child: _buildAuthGate()),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _loadFavorites,
                    color: ink,
                    backgroundColor: surface,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildTitle()),
                        if (_isLoading)
                          _buildSkeletonGrid()
                        else if (_favorites.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmpty(),
                          )
                        else ...[
                          SliverToBoxAdapter(child: _buildToolbar()),
                          _gridMode ? _buildGrid() : _buildList(),
                        ],
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

  Widget _buildHeader({bool showActions = true}) {
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
          Row(
            children: [
              if (showActions && _favorites.isNotEmpty) ...[
                GestureDetector(
                  onTap: _clearAll,
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
                ),
                const SizedBox(width: 8),
              ],
              Consumer<AuthService>(
                builder: (ctx, auth, _) =>
                    auth.isAuthenticated ? _buildAvatarBtn(auth) : _buildLoginBtn(),
              ),
            ],
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
            'Избранное',
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
            _isLoading
                ? 'Загрузка...'
                : (_favorites.isEmpty
                    ? 'Пока пусто'
                    : 'Сохранено ${_favorites.length} товаров'),
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

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          // Сводка по сумме
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: line, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 14, color: ink),
                  const SizedBox(width: 6),
                  Text(
                    _formatPrice(_totalPrice()),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
                  ),
                  const SizedBox(width: 6),
                  const Text('·',
                      style: TextStyle(fontSize: 12, color: inkSoft, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('${_favorites.length} шт.',
                      style: const TextStyle(fontSize: 12, color: inkSoft, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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

  double _totalPrice() {
    double sum = 0;
    for (final p in _favorites) {
      sum += p.price;
    }
    return sum;
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
          (ctx, i) => _buildProductCard(_favorites[i]),
          childCount: _favorites.length,
        ),
      ),
    );
  }

  Widget _buildList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.separated(
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildListCard(_favorites[i]),
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
                        fallbackIcon: Icons.devices_outlined,
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
                      child: GestureDetector(
                        onTap: () => _removeFavorite(product),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, color: heart, size: 16),
                        ),
                      ),
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
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: ink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: surface, size: 16),
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
    return Dismissible(
      key: ValueKey(product.id ?? product.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: heart,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: surface, size: 20),
      ),
      onDismissed: (_) => _removeFavorite(product),
      child: GestureDetector(
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
                    fallbackIcon: Icons.devices_outlined,
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
                          GestureDetector(
                            onTap: () => _removeFavorite(product),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: line),
                              ),
                              child: const Icon(Icons.favorite_rounded, color: heart, size: 14),
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
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _shimmerWrap(child: _skeletonGridCard(showBadge: i.isEven)),
          childCount: 4,
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      sliver: SliverList.separated(
        itemCount: 4,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Декоративная иллюстрация: круг с сердцем + два параллельных кружка
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
                  child: const Icon(Icons.favorite_border_rounded, color: ink, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Пока пусто',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Сохраняйте товары, которые\nпонравились, чтобы вернуться к ним позже',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: inkSoft, height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
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

  Widget _buildAuthGate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: ink, size: 32),
          ),
          const SizedBox(height: 24),
          const Text(
            'Войдите в аккаунт',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Чтобы видеть избранное на всех\nустройствах, нужен вход',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: inkSoft, height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(context,
                CircleRevealPageRoute(page: const LoginScreen(), color: ink, icon: Icons.login_rounded)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text('Войти',
                  style: TextStyle(fontSize: 13, color: surface, fontWeight: FontWeight.w600)),
            ),
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
}
