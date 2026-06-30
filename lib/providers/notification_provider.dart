import 'package:flutter/foundation.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.title,
    required this.body,
    DateTime? receivedAt,
    this.data,
  }) : receivedAt = receivedAt ?? DateTime.now();
}

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  void addNotification(AppNotification n, {bool markUnread = true}) {
    _notifications.insert(0, n);
    if (markUnread) _unreadCount++;
    notifyListeners();
  }

  void markAllRead() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}
