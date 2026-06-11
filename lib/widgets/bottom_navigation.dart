import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../widgets/page_transition.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/all_properties_screen.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';

/// Нижняя навигация, которая сама определяет активную вкладку
/// по типу виджета текущего экрана — без ручного `selectedIndex`.
/// Параметры `selectedIndex` и `onItemSelected` оставлены для
/// обратной совместимости, но игнорируются.
class CustomBottomNavigation extends StatelessWidget {
  // Оставлены для совместимости — не используются.
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const CustomBottomNavigation({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color accent = Color(0xFFFF3B30);

  void _navigate(BuildContext context, int index, int current) {
    if (index == current) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          CircleRevealPageRoute(
              page: const HomeScreen(), color: ink, icon: Icons.home_rounded),
          (_) => false,
        );
        break;
      case 1:
        Navigator.push(context,
            CircleRevealPageRoute(
                page: const AllPropertiesScreen(),
                color: ink,
                icon: Icons.grid_view_rounded));
        break;
      case 2:
        Navigator.push(context,
            CircleRevealPageRoute(
                page: const FavoritesScreen(),
                color: ink,
                icon: Icons.favorite_rounded));
        break;
      case 3:
        Navigator.push(context,
            CircleRevealPageRoute(
                page: const CartScreen(),
                color: ink,
                icon: Icons.shopping_bag_rounded));
        break;
    }
  }

  void _openProfile(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    Navigator.push(
      context,
      CircleRevealPageRoute(
        page: auth.isAuthenticated ? const ProfileScreen() : const LoginScreen(),
        color: ink,
        icon: auth.isAuthenticated ? Icons.person_rounded : Icons.login_rounded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartService>().count;

    // Слушаем навигацию через RouteObserver-like подход:
    // перестраиваемся при каждом build (вызывается при pop/push).
    final current = _currentIndex(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 64,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: line, width: 1),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _item(context, 0, Icons.home_outlined, Icons.home_rounded, current),
            _item(context, 1, Icons.grid_view_outlined, Icons.grid_view_rounded, current),
            _item(context, 2, Icons.favorite_border_rounded, Icons.favorite_rounded, current),
            _item(context, 3, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, current,
                badge: cartCount > 0 ? cartCount : null,
                onLongPress: () => _openProfile(context)),
          ],
        ),
      ),
    );
  }

  /// Определяем активную вкладку по типу виджета,
  /// который содержит эту навигацию (поднимаемся по дереву).
  int _currentIndex(BuildContext context) {
    Widget? screenWidget;
    context.visitAncestorElements((element) {
      final w = element.widget;
      if (w is HomeScreen ||
          w is AllPropertiesScreen ||
          w is FavoritesScreen ||
          w is CartScreen) {
        screenWidget = w;
        return false;
      }
      return true;
    });

    if (screenWidget is AllPropertiesScreen) return 1;
    if (screenWidget is FavoritesScreen) return 2;
    if (screenWidget is CartScreen) return 3;
    return 0;
  }

  Widget _item(
    BuildContext context,
    int index,
    IconData iconOff,
    IconData iconOn,
    int current, {
    int? badge,
    VoidCallback? onLongPress,
  }) {
    final selected = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigate(context, index, current),
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? ink : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                selected ? iconOn : iconOff,
                size: 22,
                color: selected ? surface : inkSoft,
              ),
              if (badge != null)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: selected ? ink : surface,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: surface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
