import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/news_repository.dart';
import 'auth_state.dart';

/// Tab Thông báo (V2): bài viết admin đăng, kèm trạng thái đã đọc theo tài khoản.
///
/// Chưa có thông báo đẩy (backend chưa lưu token thiết bị, app chưa có
/// Firebase) — "nhận thông báo" ở đây là chấm đỏ trên tab khi có bài mới,
/// tải lại khi mở app/mở tab. Chỉ tính cho người đã đăng nhập.
///
/// Đã đọc lưu trên máy theo id tài khoản, không lên server (backend không có
/// chỗ lưu). "Mới" = đăng sau lần đầu tài khoản đó dùng tab trên máy này: không
/// có mốc này thì lần đầu đăng nhập cả 10 bài cũ đều thành chưa đọc.
class NewsInboxController extends ChangeNotifier {
  NewsInboxController({NewsRepository? news, AuthController? auth})
    : _news = news ?? NewsRepository.instance,
      _auth = auth ?? AuthController.instance {
    _news.addListener(notifyListeners);
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  static NewsInboxController? _instance;

  static NewsInboxController get instance =>
      _instance ??= NewsInboxController();

  @visibleForTesting
  static set instance(NewsInboxController controller) => _instance = controller;

  final NewsRepository _news;
  final AuthController _auth;

  /// Giữ tối đa chừng này id đã đọc — danh sách chỉ có 10 bài mới nhất nên id
  /// cũ hơn nữa không bao giờ hiện lại.
  static const _maxReadIds = 200;

  String? _userId;
  DateTime? _since;
  Set<String> _readIds = {};

  bool get isLoggedIn => _userId != null;

  /// Bài để hiện ở tab — khách thì rỗng (tab mời đăng nhập).
  List<NewsItem> get items => isLoggedIn ? _news.items : const [];

  bool get isLoading => _news.isLoading;

  bool isUnread(NewsItem item) {
    if (!isLoggedIn || _readIds.contains(item.id)) return false;
    final since = _since;
    final at = item.publishedAt;
    // Chưa nạp xong mốc thì chưa tính gì là mới, khỏi chấm đỏ nhấp nháy.
    if (since == null || at == null) return false;
    return at.isAfter(since);
  }

  int get unreadCount => items.where(isUnread).length;

  Future<void> refresh() => _news.refresh();

  void markRead(NewsItem item) {
    if (!isLoggedIn || !_readIds.add(item.id)) return;
    notifyListeners();
    unawaited(_save());
  }

  void markAllRead() {
    final unread = items.where(isUnread).map((i) => i.id).toList();
    if (unread.isEmpty) return;
    _readIds.addAll(unread);
    notifyListeners();
    unawaited(_save());
  }

  void _onAuthChanged() {
    final id = _auth.user?.id;
    if (id == _userId) return;
    _userId = id;
    _since = null;
    _readIds = {};
    notifyListeners();
    if (id != null) unawaited(_load(id));
  }

  String _sinceKey(String id) => 'newsInbox.since.$id';
  String _readKey(String id) => 'newsInbox.read.$id';

  Future<void> _load(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var since = DateTime.tryParse(prefs.getString(_sinceKey(id)) ?? '');
      if (since == null) {
        since = DateTime.now();
        await prefs.setString(_sinceKey(id), since.toIso8601String());
      }
      final read = prefs.getStringList(_readKey(id)) ?? const [];
      // Đổi tài khoản giữa lúc đang đọc ổ đĩa → bỏ kết quả của tài khoản cũ.
      if (_userId != id) return;
      _since = since;
      _readIds = {...read, ..._readIds};
      notifyListeners();
    } catch (_) {
      // Không đọc được bộ nhớ máy thì coi như mới dùng: không có bài "mới".
    }
  }

  Future<void> _save() async {
    final id = _userId;
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _readIds.toList();
      await prefs.setStringList(
        _readKey(id),
        ids.length > _maxReadIds ? ids.sublist(ids.length - _maxReadIds) : ids,
      );
    } catch (_) {
      // Lưu hỏng thì lần sau bài đó lại hiện chưa đọc — không đáng báo lỗi.
    }
  }

  @override
  void dispose() {
    _news.removeListener(notifyListeners);
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
