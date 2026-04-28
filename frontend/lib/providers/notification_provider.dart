import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../core/constants.dart';

class NotificationItem {
  final String id;
  final String type;
  final String priority;
  final String title;
  final String message;
  bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'system',
      priority: json['priority'] as String? ?? 'medium',
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NotificationItem> get unread =>
      _notifications.where((n) => !n.isRead).toList();

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadNotifications({bool unreadOnly = false, String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (unreadOnly) params['unread'] = 'true';
      if (type != null && type.isNotEmpty) params['type'] = type;

      final res = await _api.get(
        ApiConstants.notifications,
        queryParameters: params,
      );

      final results = res.data['results'] as List? ?? [];
      _notifications = results
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = res.data['unread_count'] as int? ?? 0;
    } catch (e) {
      _error = 'Failed to load notifications.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Lightweight poll – only fetches the unread count (used by the bell badge).
  Future<void> refreshUnreadCount() async {
    try {
      final res = await _api.get(ApiConstants.notificationsUnreadCount);
      final count = res.data['unread_count'] as int? ?? 0;
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── Mark read ────────────────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    try {
      await _api.patch('${ApiConstants.notifications}$id/read/');
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx].isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.post(ApiConstants.notificationsMarkAllRead);
      for (final n in _notifications) {
        n.isRead = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteNotification(String id) async {
    try {
      await _api.delete('${ApiConstants.notifications}$id/');
      final removed = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => NotificationItem(
          id: '', type: '', priority: '', title: '', message: '',
          isRead: true, createdAt: DateTime.now(),
        ),
      );
      if (removed.id.isNotEmpty) {
        _notifications.removeWhere((n) => n.id == id);
        if (!removed.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteByFilter({bool unreadOnly = false, String? type}) async {
    // Collect IDs to delete based on the filter
    final toDelete = _notifications.where((n) {
      if (unreadOnly) return !n.isRead;
      if (type != null) return n.type == type;
      return true; // all
    }).map((n) => n.id).toList();

    if (toDelete.isEmpty) return;

    // Fire-and-forget individual deletes in parallel
    await Future.wait(
      toDelete.map((id) => _api.delete('${ApiConstants.notifications}$id/')),
    );

    final removedUnread = _notifications
        .where((n) => toDelete.contains(n.id) && !n.isRead)
        .length;

    _notifications.removeWhere((n) => toDelete.contains(n.id));
    _unreadCount = (_unreadCount - removedUnread).clamp(0, 9999);
    notifyListeners();
  }

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _error = null;
    notifyListeners();
  }
}
