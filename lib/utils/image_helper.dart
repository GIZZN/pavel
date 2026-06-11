import 'dart:convert';
import 'dart:typed_data';

class ImageHelper {
  /// Безопасное декодирование base64 строки в байты
  /// Автоматически удаляет префикс data:image/... или file:/// если он присутствует
  static Uint8List? safeBase64Decode(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      // Удаляем префикс file:/// если он есть
      String cleanBase64 = base64String;
      if (cleanBase64.startsWith('file:///')) {
        cleanBase64 = cleanBase64.substring(8);
      }
      
      // Удаляем префикс data:image/... если он есть
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      // Удаляем пробелы и переносы строк
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

      // Декодируем
      return base64Decode(cleanBase64);
    } catch (e) {
      print('❌ Ошибка декодирования base64: $e');
      print('   Длина строки: ${base64String.length}');
      if (base64String.length > 50) {
        print('   Первые 50 символов: ${base64String.substring(0, 50)}');
      }
      return null;
    }
  }

  /// Проверяет, является ли строка валидным base64
  static bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    try {
      String cleanBase64 = base64String;
      if (cleanBase64.startsWith('file:///')) {
        cleanBase64 = cleanBase64.substring(8);
      }
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      base64Decode(cleanBase64);
      return true;
    } catch (e) {
      return false;
    }
  }
}
