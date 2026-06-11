import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/orders_service.dart';
import '../utils/image_helper.dart';
import '../widgets/page_transition.dart';
import '../widgets/bottom_navigation.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedBottomNav = 3;

  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color danger = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: line, width: 1),
                  ),
                  child: const Icon(Icons.person_off_outlined, size: 28, color: inkSoft),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Пользователь не найден',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildAvatarBlock(user)),
                SliverToBoxAdapter(child: _buildStatsRow(user)),
                SliverToBoxAdapter(child: _buildSectionTitle('Аккаунт')),
                SliverToBoxAdapter(child: _buildAccountCard(user)),
                SliverToBoxAdapter(child: _buildSectionTitle('Действия')),
                SliverToBoxAdapter(child: _buildActions()),
                SliverToBoxAdapter(child: _buildSectionTitle('Настройки')),
                SliverToBoxAdapter(child: _buildSettings()),
                SliverToBoxAdapter(child: _buildLogout(auth)),
                SliverToBoxAdapter(child: _buildVersion()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
          GestureDetector(
            onTap: () => Navigator.push(context,
                CircleRevealPageRoute(
                    page: const EditProfileScreen(),
                    color: ink,
                    icon: Icons.edit_outlined)),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, color: surface, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Редактировать',
                    style: TextStyle(fontSize: 12, color: surface, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarBlock(dynamic user) {
    final avatarBytes = user.avatarUrl != null && user.avatarUrl!.isNotEmpty
        ? ImageHelper.safeBase64Decode(user.avatarUrl)
        : null;

    final initials = _getInitials(user.name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1),
            ),
            child: ClipOval(
              child: avatarBytes != null
                  ? Image.memory(avatarBytes,
                      fit: BoxFit.cover,
                      width: 96,
                      height: 96,
                      errorBuilder: (_, __, ___) => _avatarFallback(initials))
                  : _avatarFallback(initials),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 14, color: inkSoft, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: line),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 12, color: ink),
                SizedBox(width: 4),
                Text(
                  'Подтверждённый аккаунт',
                  style: TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String initials) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildStatsRow(dynamic user) {
    final reg = user.createdAt != null
        ? '${user.createdAt!.day.toString().padLeft(2, '0')}.${user.createdAt!.month.toString().padLeft(2, '0')}'
        : '—';

    final favCount = context.watch<FavoritesService>().favoriteIds.length;
    final ordersCount = context.watch<OrdersService>().orders.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          _statCell('$ordersCount', 'Заказов'),
          _statDivider(),
          _statCell('$favCount', 'В избранном'),
          _statDivider(),
          _statCell(reg, 'С нами'),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 32, color: line);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: inkSoft,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAccountCard(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: Column(
          children: [
            _accountRow(Icons.alternate_email_rounded, 'Email', user.email),
            _rowDivider(),
            _accountRow(Icons.phone_outlined, 'Телефон', user.phone ?? 'Не указан'),
            _rowDivider(),
            _accountRow(
              Icons.calendar_today_outlined,
              'Дата регистрации',
              user.createdAt != null
                  ? '${user.createdAt!.day.toString().padLeft(2, '0')}.${user.createdAt!.month.toString().padLeft(2, '0')}.${user.createdAt!.year}'
                  : 'Не указана',
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() => Padding(
        padding: const EdgeInsets.only(left: 60),
        child: Container(height: 1, color: line),
      );

  Widget _accountRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ink,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: Column(
          children: [
            _menuRow(
              Icons.favorite_border_rounded,
              'Избранное',
              'Сохранённые товары',
              () => Navigator.push(context,
                  CircleRevealPageRoute(
                      page: const FavoritesScreen(),
                      color: ink,
                      icon: Icons.favorite_outline_rounded)),
            ),
            _rowDivider(),
            _menuRow(
              Icons.receipt_long_outlined,
              'Заказы',
              'История покупок',
              () => Navigator.push(context,
                  CircleRevealPageRoute(
                      page: const OrdersScreen(),
                      color: ink,
                      icon: Icons.receipt_long_outlined)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: Column(
          children: [
            _menuRow(Icons.notifications_none_rounded, 'Уведомления',
                'Push, email, SMS', () {}),
            _rowDivider(),
            _menuRow(Icons.language_rounded, 'Язык', 'Русский', () {}),
            _rowDivider(),
            _menuRow(Icons.shield_outlined, 'Конфиденциальность',
                'Безопасность аккаунта', () {}),
            _rowDivider(),
            _menuRow(Icons.help_outline_rounded, 'Поддержка',
                'Помощь и FAQ', () {}),
          ],
        ),
      ),
    );
  }

  Widget _menuRow(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: ink),
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
            const Icon(Icons.chevron_right_rounded, color: inkSoft, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogout(AuthService auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: GestureDetector(
        onTap: () => _confirmLogout(auth),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, size: 16, color: danger),
              SizedBox(width: 8),
              Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  fontSize: 14,
                  color: danger,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(AuthService auth) async {
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
                'Выйти из аккаунта?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Чтобы вернуться, нужно будет войти заново.',
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
                        child: const Text(
                          'Отмена',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                        ),
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
                        child: const Text(
                          'Выйти',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: surface),
                        ),
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

    if (ok == true && mounted) {
      await auth.logout();
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildVersion() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Center(
        child: Text(
          'Версия 1.0.0',
          style: TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
