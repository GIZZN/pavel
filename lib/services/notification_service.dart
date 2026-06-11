import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          Clipboard.setData(ClipboardData(text: details.payload!));
        }
      },
    );

    if (initialized == true) {
      // Запрашиваем разрешение на уведомления для Android 13+
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      _initialized = true;
      debugPrint('✅ Уведомления инициализированы');
    } else {
      debugPrint('❌ Не удалось инициализировать уведомления');
    }
  }

  static Future<void> showPasswordResetNotification(String code) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'password_reset',
        'Восстановление пароля',
        channelDescription: 'Уведомления о восстановлении пароля',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Код восстановления пароля',
        'Ваш код: $code (действителен 15 минут)',
        notificationDetails,
        payload: code,
      );
      
      debugPrint('✅ Уведомление отправлено: $code');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления: $e');
    }
  }

  static Future<void> showChatMessageNotification({
    required String senderName,
    required String message,
    required int senderId,
  }) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Сообщения',
        channelDescription: 'Уведомления о новых сообщениях в чате',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        senderId, // Используем senderId как ID уведомления
        senderName,
        message,
        notificationDetails,
        payload: senderId.toString(),
      );
      
      debugPrint('✅ Уведомление о сообщении от $senderName');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления: $e');
    }
  }

  static Future<void> showOrderUpdate({
    required String orderId,
    required String title,
    required String body,
  }) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'order_updates',
        'Заказы',
        channelDescription: 'Статусы заказов: в пути, доставлен',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      // Уникальный id уведомления = hash от orderId + title
      final id = (orderId.hashCode ^ title.hashCode) & 0x7fffffff;

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: orderId,
      );

      debugPrint('✅ Push: $title — $body');
    } catch (e) {
      debugPrint('❌ Ошибка push заказа: $e');
    }
  }
}
