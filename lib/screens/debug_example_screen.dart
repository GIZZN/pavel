import 'package:flutter/material.dart';
import '../utils/debug_helpers.dart';

/// 🔍 Пример экрана с демонстрацией отладочных инструментов
/// Используйте этот экран для тестирования и обучения

class DebugExampleScreen extends StatelessWidget {
  const DebugExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Примеры отладки'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Визуализация границ',
              debugBorder(
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text('Виджет с красной рамкой'),
                ),
                color: Colors.red,
              ),
            ),
            
            _buildSection(
              '2. Проверка размеров (смотрите консоль)',
              debugSize(
                Container(
                  width: 200,
                  height: 100,
                  color: Colors.blue.withOpacity(0.2),
                  child: const Center(child: Text('200x100')),
                ),
                label: 'Синий контейнер',
              ),
            ),
            
            _buildSection(
              '3. Цветная подсветка',
              debugColor(
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text('Виджет с зеленым фоном'),
                ),
                color: Colors.green,
              ),
            ),
            
            _buildSection(
              '4. Безопасный текст (не вызывает overflow)',
              const SafeText(
                'Это очень длинный текст который обычно вызвал бы overflow но SafeText автоматически обрезает его',
                style: TextStyle(fontSize: 16),
                maxLines: 2,
              ),
            ),
            
            _buildSection(
              '5. Безопасный Row',
              SafeRow(
                children: List.generate(
                  10,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(16),
                    color: Colors.purple.withOpacity(0.2),
                    child: Text('Item ${index + 1}'),
                  ),
                ),
              ),
            ),
            
            _buildSection(
              '6. Информация при нажатии',
              DebugTapInfo(
                label: 'Кнопка',
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  child: const Text('Нажми для отладки'),
                ),
              ),
            ),
            
            _buildSection(
              '7. Мониторинг производительности (смотрите консоль)',
              PerformanceMonitor(
                label: 'Список элементов',
                child: Column(
                  children: List.generate(
                    5,
                    (index) => ListTile(
                      leading: const Icon(Icons.home),
                      title: Text('Элемент ${index + 1}'),
                      subtitle: const Text('Описание'),
                    ),
                  ),
                ),
              ),
            ),
            
            _buildSection(
              '8. Пример overflow (закомментирован)',
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Раскомментируйте код ниже чтобы увидеть overflow:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '// Row(\n'
                      '//   children: [\n'
                      '//     Text("Очень длинный текст"),\n'
                      '//     Text("Еще длинный текст"),\n'
                      '//     Text("И еще текст"),\n'
                      '//   ],\n'
                      '// )',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Инструкции
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Как использовать:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('1. Смотрите консоль для вывода размеров'),
                  SizedBox(height: 4),
                  Text('2. Нажимайте на виджеты с DebugTapInfo'),
                  SizedBox(height: 4),
                  Text('3. Проверяйте время рендеринга в консоли'),
                  SizedBox(height: 4),
                  Text('4. Используйте эти утилиты в своем коде'),
                  SizedBox(height: 12),
                  Text(
                    '📚 Читайте DEBUG_GUIDE.md для подробностей',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
