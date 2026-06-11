import 'package:flutter/material.dart';

/// Универсальное превью товара.
/// - Сеть: показывает Image.network с placeholder и errorBuilder
/// - Без url: показывает иконку категории
class ProductImage extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Color background;
  final Color iconColor;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.url,
    required this.fallbackIcon,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
    this.background = const Color(0xFFFAFAFA),
    this.iconColor = const Color(0xFF6B6B6B),
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: background,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: iconSize, color: iconColor.withValues(alpha: 0.4)),
    );

    if (url == null || url!.isEmpty) return ClipRRect(borderRadius: borderRadius, child: placeholder);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: background,
            alignment: Alignment.center,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor.withValues(alpha: 0.5),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
