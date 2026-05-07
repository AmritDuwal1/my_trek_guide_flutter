import 'package:flutter/material.dart';
import 'package:tour_mobile/notifications/notification_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore.instance;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: () => _store.markAllRead(),
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: () => _store.clearAll(),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final items = _store.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TravelColors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = items[i];
              return Material(
                color: TravelColors.surface,
                borderRadius: BorderRadius.circular(18),
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _store.markRead(n.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: n.read ? Colors.transparent : TravelColors.navActive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.body,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: TravelColors.muted,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _timeLabel(n.createdAtMs),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: TravelColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, color: TravelColors.muted),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _timeLabel(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

