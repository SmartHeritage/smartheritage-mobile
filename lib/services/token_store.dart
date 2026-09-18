import 'package:shared_preferences/shared_preferences.dart';

/// Lưu cặp token JWT giữa các lần mở app.
///
/// Giữ trong bộ nhớ một bản sao để [accessToken] đọc được đồng bộ — mỗi request
/// đều cần nó, không thể `await` SharedPreferences ở từng lần gọi.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';

  String? _access;
  String? _refresh;
  bool _loaded = false;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  bool get hasSession => _refresh != null;

  /// Đọc token đã lưu. Gọi một lần lúc khởi động trước khi dựng UI.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString(_accessKey);
    _refresh = prefs.getString(_refreshKey);
    _loaded = true;
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
