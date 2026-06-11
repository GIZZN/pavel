import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/favorites_service.dart';
import 'services/cart_service.dart';
import 'services/orders_service.dart';
import 'services/inbox_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Подключение к БД только для мобильных/десктоп платформ
  if (!kIsWeb) {
    try {
      await DatabaseService.instance.connect();
    } catch (e) {
      debugPrint('Warning: Could not connect to database: $e');
      debugPrint('App will work without database');
    }
    
    // Инициализация уведомлений
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Warning: Could not initialize notifications: $e');
    }
  }
  
  // Визуальная отладка - выключена
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesService(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartService()..load(null),
        ),
        ChangeNotifierProvider(
          create: (_) => OrdersService()..load(null),
        ),
        ChangeNotifierProvider(
          create: (_) => InboxService()..load(null),
        ),
      ],
      child: Builder(
        builder: (ctx) {
          // Связываем заказы → inbox
          OrdersService.onOrderEvent = (id, title, body) {
            ctx.read<InboxService>().push(
                  id: id,
                  type: InboxType.orderStatus,
                  title: title,
                  body: body,
                );
          };
          return _AuthSyncGate(
            child: MaterialApp(
              title: 'Магазин техники',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A0A0A)),
                useMaterial3: true,
              ),
              home: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// Перезагружает сервисы (Cart, Inbox, Orders, Favorites) при смене userId.
class _AuthSyncGate extends StatefulWidget {
  final Widget child;
  const _AuthSyncGate({required this.child});

  @override
  State<_AuthSyncGate> createState() => _AuthSyncGateState();
}

class _AuthSyncGateState extends State<_AuthSyncGate> {
  int? _lastUserId;
  bool _initialSync = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.currentUser?.id;

    if (!_initialSync || uid != _lastUserId) {
      _initialSync = true;
      _lastUserId = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await context.read<CartService>().load(uid);
        await context.read<InboxService>().load(uid);
        await context.read<OrdersService>().load(uid);
        if (uid != null) {
          await context.read<FavoritesService>().loadFavorites(uid);
        } else {
          context.read<FavoritesService>().clear();
        }
      });
    }

    return widget.child;
  }
}
