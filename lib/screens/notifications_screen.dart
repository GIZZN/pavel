import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/inbox_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color accent = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final inbox = context.read<InboxService>();
    inbox.load(auth.currentUser?.id).then((_) {
      // Помечаем все как прочитанные при открытии экрана
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) inbox.markAllRead();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<InboxService>();
    final items = inbox.items;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(items.isNotEmpty),
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        _buildTitle(items.length),
                        const SizedBox(height: 24),
                        ...items.map((it) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildItemCard(it),
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasItems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: line, width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: ink),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Уведомления',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
            ),
          ),
          if (hasItems)
            GestureDetector(
              onTap: _confirmClear,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: line, width: 1),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: ink),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Удалить все?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              const Text('Все уведомления будут удалены без возможности восстановления.',
                  style: TextStyle(fontSize: 13, color: inkSoft, height: 1.4)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: line),
                        ),
                        child: const Text('Отмена',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('Удалить',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: surface)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      await context.read<InboxService>().clear();
    }
  }

  Widget _buildTitle(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Уведомления',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Всего $count',
          style: const TextStyle(fontSize: 14, color: inkSoft),
        ),
      ],
    );
  }

  Widget _buildItemCard(InboxItem it) {
    final iconData = _iconFor(it.type);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, size: 18, color: ink),
              ),
              if (!it.read)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        it.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(it.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  it.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: inkSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(InboxType t) {
    switch (t) {
      case InboxType.orderStatus: return Icons.local_shipping_outlined;
      case InboxType.promo: return Icons.local_offer_outlined;
      case InboxType.system: return Icons.info_outline_rounded;
    }
  }

  String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    if (diff.inDays < 7) return '${diff.inDays} дн';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}.${d.month.toString().padLeft(2, '0')} $h:$m';
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: line, width: 1),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface,
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    border: Border.all(color: line, width: 1),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: ink, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Уведомлений нет',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Здесь появятся обновления заказов\nи акции магазина',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}
