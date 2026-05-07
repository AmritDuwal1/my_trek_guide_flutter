import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_mobile/notifications/app_notification.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  static const _prefsKey = 'tour_notifications_v1';

  bool _loaded = false;
  List<AppNotification> _items = const [];

  List<AppNotification> get items => _items;
  int get unreadCount => _items.where((n) => !n.read).length;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _items = const [];
      notifyListeners();
      return;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      _items = list;
    } catch (_) {
      // If storage got corrupted, reset.
      _items = const [];
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> add({
    required String title,
    required String body,
  }) async {
    await ensureLoaded();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${now}_${title.hashCode}_${body.hashCode}';
    final next = [
      AppNotification(id: id, title: title, body: body, createdAtMs: now, read: false),
      ..._items,
    ];
    // Keep recent 200.
    _items = next.take(200).toList(growable: false);
    await _persist();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await ensureLoaded();
    final next = _items.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(growable: false);
    _items = next;
    await _persist();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await ensureLoaded();
    _items = _items.map((n) => n.read ? n : n.copyWith(read: true)).toList(growable: false);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await ensureLoaded();
    _items = const [];
    await _persist();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _items = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}

