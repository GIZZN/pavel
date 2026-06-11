import 'package:flutter/material.dart';

class CustomSnackbar {
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _inkSoft = Color(0xFF6B6B6B);
  static const Color _line = Color(0xFFEAEAEA);
  static const Color _success = Color(0xFF00B26A);
  static const Color _danger = Color(0xFFFF3B30);
  static const Color _warning = Color(0xFFFFAA00);

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackbarWidget(
        message: message,
        type: type,
        icon: icon,
        onDismiss: () {
          if (overlayEntry.mounted) overlayEntry.remove();
        },
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }

  static void success(BuildContext context, String message, {IconData? icon}) =>
      show(context, message: message, type: SnackbarType.success, icon: icon);

  static void error(BuildContext context, String message, {IconData? icon}) =>
      show(context, message: message, type: SnackbarType.error, icon: icon);

  static void warning(BuildContext context, String message, {IconData? icon}) =>
      show(context, message: message, type: SnackbarType.warning, icon: icon);

  static void info(BuildContext context, String message, {IconData? icon}) =>
      show(context, message: message, type: SnackbarType.info, icon: icon);
}

enum SnackbarType { success, error, warning, info }

class _CustomSnackbarWidget extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final IconData? icon;
  final VoidCallback onDismiss;
  final Duration duration;

  const _CustomSnackbarWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
    this.icon,
  });

  @override
  State<_CustomSnackbarWidget> createState() => _CustomSnackbarWidgetState();
}

class _CustomSnackbarWidgetState extends State<_CustomSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case SnackbarType.success: return CustomSnackbar._success;
      case SnackbarType.error: return CustomSnackbar._danger;
      case SnackbarType.warning: return CustomSnackbar._warning;
      case SnackbarType.info: return CustomSnackbar._ink;
    }
  }

  IconData get _icon {
    if (widget.icon != null) return widget.icon!;
    switch (widget.type) {
      case SnackbarType.success: return Icons.check_rounded;
      case SnackbarType.error: return Icons.close_rounded;
      case SnackbarType.warning: return Icons.warning_amber_rounded;
      case SnackbarType.info: return Icons.info_outline_rounded;
    }
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < 0) _dismiss();
                  },
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: CustomSnackbar._surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CustomSnackbar._line, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: CustomSnackbar._ink.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_icon, color: _accentColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: CustomSnackbar._ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              height: 1.3,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _dismiss,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: CustomSnackbar._bg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: CustomSnackbar._inkSoft,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
