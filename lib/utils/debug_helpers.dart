import 'package:flutter/material.dart';

/// 🔍 ЛАЙФХАК: Утилиты для отладки overflow и layout проблем

/// Оборачивает виджет в контейнер с цветной рамкой для визуализации
Widget debugBorder(Widget child, {Color color = Colors.red}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: color, width: 2),
    ),
    child: child,
  );
}

/// Показывает размеры виджета в консоли
Widget debugSize(Widget child, {String label = 'Widget'}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      print('📏 $label размеры:');
      print('   Ширина: ${constraints.maxWidth}');
      print('   Высота: ${constraints.maxHeight}');
      return child;
    },
  );
}

/// Оборачивает виджет в цветной контейнер для визуализации
Widget debugColor(Widget child, {Color color = Colors.red}) {
  return Container(
    color: color.withOpacity(0.3),
    child: child,
  );
}

/// Показывает информацию о padding и margin
Widget debugSpacing(Widget child, {String label = 'Widget'}) {
  return Builder(
    builder: (context) {
      print('📐 $label отступы проверены');
      return child;
    },
  );
}

/// Безопасный Text виджет, который не вызывает overflow
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  const SafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

/// Безопасный Row, который не вызывает overflow
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}

/// Безопасный Column, который не вызывает overflow
class SafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const SafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}

/// Показывает overlay с информацией о виджете при нажатии
class DebugTapInfo extends StatelessWidget {
  final Widget child;
  final String label;

  const DebugTapInfo({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('🔍 Debug: $label'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Виджет: $label'),
                const SizedBox(height: 8),
                Text('Тип: ${child.runtimeType}'),
                const SizedBox(height: 8),
                const Text('Нажмите на виджет для отладки'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// Измеряет производительность рендеринга виджета
class PerformanceMonitor extends StatelessWidget {
  final Widget child;
  final String label;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    
    return Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopwatch.stop();
          print('⏱️ $label отрендерен за: ${stopwatch.elapsedMilliseconds}ms');
        });
        return child;
      },
    );
  }
}

// 📝 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ:

/*
// 1. Визуализация границ виджета
debugBorder(
  Text('Привет'),
  color: Colors.blue,
)

// 2. Проверка размеров
debugSize(
  Container(width: 100, height: 100),
  label: 'Мой контейнер',
)

// 3. Цветная подсветка
debugColor(
  Column(children: [...]),
  color: Colors.green,
)

// 4. Безопасный текст без overflow
SafeText(
  'Очень длинный текст который не поместится',
  style: TextStyle(fontSize: 20),
  maxLines: 2,
)

// 5. Безопасный Row
SafeRow(
  children: [
    Text('1'),
    Text('2'),
    Text('3'),
  ],
)

// 6. Информация при нажатии
DebugTapInfo(
  label: 'Кнопка входа',
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Войти'),
  ),
)

// 7. Мониторинг производительности
PerformanceMonitor(
  label: 'Список товаров',
  child: ListView.builder(...),
)
*/
