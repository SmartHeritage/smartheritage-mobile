import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Trạng thái thông báo dùng chung toàn app (mock, chưa gắn FCM thật).
///
/// Giữ trong bộ nhớ như [BeaconScanController]: thoát app là reset, đủ cho
/// mục đích mô phỏng luồng bấm chuông.
class NotificationController extends ChangeNotifier {
  NotificationController._();

  static final NotificationController instance = NotificationController._();

  final List<AppNotification> _items = [...MockData.notifications];
  final Set<String> _readIds = {};

  List<AppNotification> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get unreadCount =>
      _items.where((n) => !_readIds.contains(n.id)).length;

  bool isRead(String id) => _readIds.contains(id);

  void markRead(String id) {
    if (_readIds.add(id)) notifyListeners();
  }

  void markAllRead() {
    if (unreadCount == 0) return;
    _readIds.addAll(_items.map((n) => n.id));
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _readIds.clear();
    notifyListeners();
  }

  /// Trả về dữ liệu mẫu ban đầu. Singleton giữ trong bộ nhớ nên test cần cách
  /// cô lập trạng thái giữa các case.
  @visibleForTesting
  void reset() {
    _items
      ..clear()
      ..addAll(MockData.notifications);
    _readIds.clear();
    notifyListeners();
  }
}
