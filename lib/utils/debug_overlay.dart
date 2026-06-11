import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Виджет для быстрого переключения режимов визуальной отладки
class DebugOverlay extends StatefulWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showMenu = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Кнопка для открытия меню отладки
        Positioned(
          right: 16,
          bottom: 80,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.red.withOpacity(0.8),
            onPressed: () => setState(() => _showMenu = !_showMenu),
            child: const Icon(Icons.bug_report, size: 20),
          ),
        ),
        
        // Меню отладки
        if (_showMenu)
          Positioned(
            right: 16,
            bottom: 140,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐛 Визуальная отладка',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDebugSwitch(
                      'Границы виджетов',
                      debugPaintSizeEnabled,
                      (value) => setState(() => debugPaintSizeEnabled = value),
                    ),
                    _buildDebugSwitch(
                      'Базовые линии текста',
                      debugPaintBaselinesEnabled,
                      (value) => setState(() => debugPaintBaselinesEnabled = value),
                    ),
                    _buildDebugSwitch(
                      'Касания экрана',
                      debugPaintPointersEnabled,
                      (value) => setState(() => debugPaintPointersEnabled = value),
                    ),
                    _buildDebugSwitch(
                      'Радужные перерисовки',
                      debugRepaintRainbowEnabled,
                      (value) => setState(() => debugRepaintRainbowEnabled = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebugSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
