import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../models/property_model.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';
import 'custom_snackbar.dart';

class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final Uint8List? cachedImage;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;

  static const Color primaryBlue = Color(0xFF0126FF);
  static const Color primaryBlack = Color(0xFF010101);
  static const Color primaryWhite = Color(0xFFFFFFFF);

  const PropertyCard({
    super.key,
    required this.property,
    this.cachedImage,
    required this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    if (_isProcessing) return;
    
    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      CustomSnackbar.info(
        context,
        'Войдите, чтобы добавить в избранное',
        icon: Icons.login_rounded,
      );
      return;
    }

    setState(() => _isProcessing = true);

    final favService = context.read<FavoritesService>();
    final isFavorite = favService.isFavorite(widget.property.id!);
    
    // Анимация
    if (!isFavorite) {
      _controller.forward().then((_) => _controller.reverse());
    }

    // Переключаем в БД
    await favService.toggleFavorite(authService.currentUser!.id!, widget.property.id!);
    
    if (!mounted) return;
    
    setState(() => _isProcessing = false);
    
    // Уведомляем родителя об изменении
    widget.onFavoriteChanged?.call();
    
    // Показываем сообщение
    if (isFavorite) {
      CustomSnackbar.warning(
        context,
        'Удалено из избранного',
        icon: Icons.heart_broken_rounded,
      );
    } else {
      CustomSnackbar.success(
        context,
        'Добавлено в избранное',
        icon: Icons.favorite_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favService, child) {
        final isFavorite = widget.property.id != null && favService.isFavorite(widget.property.id!);
        
        return Container(
      height: 500,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: PropertyCard.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PropertyCard.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение с градиентом
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Градиентный фон
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE8D5C4),
                            Color(0xFFC8E6C9),
                            Color(0xFFF8BBD0),
                          ],
                        ),
                      ),
                    ),
                    // Изображение
                    if (widget.cachedImage != null)
                      Image.memory(
                        widget.cachedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox();
                        },
                      ),
                    // Градиент снизу для лучшей читаемости
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              PropertyCard.primaryBlack.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Бейдж площади
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: PropertyCard.primaryWhite.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: PropertyCard.primaryBlack.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.square_foot_rounded,
                              size: 16,
                              color: PropertyCard.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.property.area} м²',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: PropertyCard.primaryBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Кнопка избранного
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: _isProcessing ? null : () => _toggleFavorite(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isFavorite 
                                ? PropertyCard.primaryWhite.withValues(alpha: 0.95)
                                : PropertyCard.primaryBlack.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isFavorite
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : PropertyCard.primaryBlack.withValues(alpha: 0.1),
                                blurRadius: isFavorite ? 15 : 10,
                                spreadRadius: isFavorite ? 2 : 0,
                              ),
                            ],
                          ),
                          child: _isProcessing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isFavorite ? Colors.red : PropertyCard.primaryWhite,
                                    ),
                                  ),
                                )
                              : ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                                    CurvedAnimation(
                                      parent: _controller,
                                      curve: Curves.elasticOut,
                                    ),
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    size: 20,
                                    color: isFavorite 
                                        ? Colors.red 
                                        : PropertyCard.primaryWhite,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Бейдж типа недвижимости
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: PropertyCard.primaryWhite.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: PropertyCard.primaryBlack.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPropertyTypeIcon(widget.property.propertyType),
                              size: 14,
                              color: PropertyCard.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPropertyTypeName(widget.property.propertyType),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: PropertyCard.primaryBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Информация
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: PropertyCard.primaryWhite.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.property.location,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PropertyCard.primaryWhite.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.property.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: PropertyCard.primaryWhite,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: PropertyCard.primaryWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.property.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PropertyCard.primaryWhite,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Характеристики
                Row(
                  children: [
                    _buildFeature(Icons.bed_rounded, '${widget.property.rooms}'),
                    const SizedBox(width: 14),
                    _buildFeature(Icons.layers_rounded, widget.property.floor),
                    const SizedBox(width: 14),
                    _buildFeature(Icons.square_foot_rounded, '${widget.property.area}м²'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.property.price} млн ₽',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: PropertyCard.primaryWhite,
                            ),
                          ),
                          Text(
                            '${(widget.property.price * 1000000 / widget.property.area).toStringAsFixed(0)} ₽/м²',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: PropertyCard.primaryWhite.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Кнопка поделиться
                        GestureDetector(
                          onTap: () {
                            // Показываем снекбар при нажатии
                            CustomSnackbar.info(
                              context,
                              'Поделиться: ${widget.property.title}',
                              icon: Icons.share_rounded,
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: PropertyCard.primaryWhite.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: PropertyCard.primaryWhite,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Кнопка подробнее
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: PropertyCard.primaryWhite.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: PropertyCard.primaryWhite,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: PropertyCard.primaryWhite.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PropertyCard.primaryWhite.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  IconData _getPropertyTypeIcon(String type) {
    switch (type) {
      case 'apartment':
        return Icons.apartment_rounded;
      case 'house':
        return Icons.villa_rounded;
      case 'commercial':
        return Icons.business_rounded;
      case 'land':
        return Icons.landscape_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  String _getPropertyTypeName(String type) {
    switch (type) {
      case 'apartment':
        return 'Квартира';
      case 'house':
        return 'Дом';
      case 'commercial':
        return 'Коммерция';
      case 'land':
        return 'Участок';
      default:
        return 'Недвижимость';
    }
  }
}
