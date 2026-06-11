import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Переход «портал через иконку».
/// Без отдельного занавеса — сам чёрный круг с иконкой выполняет роль маски.
///
/// Фазы (по нормированному t = 0..1):
///   0.00..0.30 — на старой странице появляется чёрный круг с иконкой (растёт)
///   0.20..0.50 — расходятся 3 световых кольца + микро-пульс иконки
///   0.30..0.62 — круг разрастается до полного покрытия экрана
///   0.55..0.72 — иконка схлопывается в точку (видна на чёрном)
///   0.62..1.00 — из центра расходится круг с новой страницей
class CircleRevealPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Color color;
  final IconData icon;

  CircleRevealPageRoute({
    required this.page,
    this.color = const Color(0xFF0A0A0A),
    this.icon = Icons.bolt_rounded,
  }) : super(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 850),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _PortalTransition(
              animation: animation,
              color: color,
              icon: icon,
              child: child,
            );
          },
        );
}

class _PortalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final Color color;
  final IconData icon;

  const _PortalTransition({
    required this.animation,
    required this.child,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;

        // Фазы
        final dotP = _interval(t, 0.0, 0.30, Curves.easeOutBack);
        final ringsP = _interval(t, 0.20, 0.50, Curves.easeOutCubic);
        final iconAppearP = _interval(t, 0.10, 0.40, Curves.easeOutBack);
        final pulseP = _interval(t, 0.30, 0.55, Curves.easeInOut);
        final curtainP = _interval(t, 0.30, 0.62, Curves.easeInOutCubic);
        final iconShrinkP = _interval(t, 0.55, 0.72, Curves.easeInExpo);
        final revealP = _interval(t, 0.62, 1.00, Curves.easeInOutCubic);

        final size = MediaQuery.of(context).size;
        final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.55;
        final center = Offset(size.width / 2, size.height / 2);

        // Радиус «занавеса»: сначала маленький чёрный круг (dotP),
        // потом разрастается до maxRadius (curtainP).
        final dotRadius = 56.0 * dotP;
        final blackRadius = math.max(dotRadius, maxRadius * curtainP);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Новая страница, видна через расходящийся круг.
            ClipPath(
              clipper: _CircleClipper(center: center, radius: revealP * maxRadius),
              child: Transform.scale(
                scale: 0.96 + 0.04 * revealP,
                child: child,
              ),
            ),

            // 2. Чёрный круг — единственный «занавес». Закрашен только внутри радиуса.
            //    На revealP < 1: всё, что снаружи нового круга, покрыто чёрным.
            if (blackRadius > 0 && revealP < 1.0)
              IgnorePointer(
                child: ClipPath(
                  clipper: _RingClipper(
                    center: center,
                    innerRadius: revealP * maxRadius,
                    outerRadius: blackRadius,
                  ),
                  child: Container(color: color),
                ),
              ),

            // 3. Световые кольца вокруг иконки (поверх чёрного).
            if (ringsP > 0 && iconShrinkP < 1.0)
              IgnorePointer(
                child: CustomPaint(
                  painter: _RingsPainter(
                    progress: ringsP,
                    fadeOut: iconShrinkP,
                    color: Colors.white,
                  ),
                ),
              ),

            // 4. Иконка-капсула.
            if (iconAppearP > 0 && iconShrinkP < 1.0)
              IgnorePointer(
                child: Center(
                  child: Transform.scale(
                    scale: _iconScale(iconAppearP, pulseP, iconShrinkP),
                    child: Opacity(
                      opacity: (1 - iconShrinkP).clamp(0.0, 1.0),
                      child: _GlassIcon(icon: icon, fade: iconShrinkP),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _iconScale(double appear, double pulse, double shrink) {
    final pulseDelta = math.sin(pulse * math.pi) * 0.06;
    return ((appear + pulseDelta) * (1 - shrink)).clamp(0.0, 1.5);
  }
}

double _interval(double t, double start, double end, Curve curve) {
  if (t <= start) return 0.0;
  if (t >= end) return 1.0;
  return curve.transform((t - start) / (end - start));
}

/// Иконка-капсула в стеклянном стиле: белая на чёрном.
class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final double fade;
  const _GlassIcon({required this.icon, required this.fade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.22 * (1 - fade)),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }
}

/// Видимая область — круг.
class _CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  _CircleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: math.max(radius, 0.0)));
  }

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.center != center || old.radius != radius;
}

/// Видимая область — кольцо (между двумя кругами).
class _RingClipper extends CustomClipper<Path> {
  final Offset center;
  final double innerRadius;
  final double outerRadius;
  _RingClipper({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
  });

  @override
  Path getClip(Size size) {
    final outer = Path()
      ..addOval(Rect.fromCircle(center: center, radius: math.max(outerRadius, 0.0)));
    if (innerRadius <= 0) return outer;
    final inner = Path()
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  bool shouldReclip(_RingClipper old) =>
      old.center != center ||
      old.innerRadius != innerRadius ||
      old.outerRadius != outerRadius;
}

class _RingsPainter extends CustomPainter {
  final double progress;
  final double fadeOut;
  final Color color;

  _RingsPainter({required this.progress, required this.fadeOut, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const ringsCount = 3;
    final globalAlpha = (1 - fadeOut).clamp(0.0, 1.0);
    if (globalAlpha <= 0) return;

    for (int i = 0; i < ringsCount; i++) {
      final delay = i * 0.18;
      final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final radius = 50 + 180 * local;
      final alpha = (1 - local) * 0.45 * globalAlpha;
      if (alpha <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: alpha);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.progress != progress || old.fadeOut != fadeOut || old.color != color;
}
