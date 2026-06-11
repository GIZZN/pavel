import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Сервис отправки email через EmailJS.
///
/// Чтобы поменять отправщика — просто впишите свои значения в константы ниже.
/// Получить их можно в личном кабинете https://www.emailjs.com/:
/// - Public Key — Account → API Keys
/// - Service ID — Email Services
/// - Template ID — Email Templates (используется шаблон с переменными
///   {{to_email}}, {{user_name}}, {{code}})
class EmailService {
  // ============== НАСТРОЙКИ ОТПРАВИТЕЛЯ ==============
  static const String _publicKey = 'QmT0PEi2Odr0vPj7a';
  static const String _serviceId = 'service_rnf78gb';
  static const String _templateId = 'template_u3s2men';
  // ====================================================

  static const String _endpoint =
      'https://api.emailjs.com/api/v1.0/email/send';

  static bool get _isConfigured =>
      !_publicKey.startsWith('YOUR_') &&
      !_serviceId.startsWith('YOUR_') &&
      !_templateId.startsWith('YOUR_');

  /// Отправляет письмо с кодом восстановления пароля.
  /// Возвращает true при успехе. При неудаче — false (silent fail для UI).
  static Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String userName,
    required String resetCode,
  }) async {
    if (!_isConfigured) {
      debugPrint('⚠️ EmailService: ключи отправщика не настроены — письмо не отправлено');
      return false;
    }

    try {
      debugPrint('📨 EmailService: отправка на $toEmail с кодом $resetCode');

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': <String, String>{
            'to_email': toEmail,
            'user_name': userName,
            'code': resetCode,
            'app_name': 'Магазин техники',
          },
        }),
      );

      debugPrint('📬 EmailJS status: ${response.statusCode}');
      debugPrint('📬 EmailJS body:   ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Email отправлен: $toEmail');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ EmailService exception: $e');
      return false;
    }
  }
}
