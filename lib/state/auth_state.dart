import 'dart:async';

import 'package:flutter/material.dart';

import '../data/favorite_repository.dart';
import '../l10n/l10n.dart';
import '../screens/auth/complete_phone_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/api_client.dart';
import '../services/google_auth.dart';
import '../services/token_store.dart';

/// Người dùng đang đăng nhập, dựng từ `GET /auth/me`.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.gender,
    this.avatarUrl,
    this.googleUid,
    this.preferredLanguage = 'vi',
    this.notificationsEnabled = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        gender: json['gender'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        googleUid: json['googleUid'] as String?,
        preferredLanguage: (json['preferredLanguage'] as String?) ?? 'vi',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      );

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? gender;
  final String? avatarUrl;

  /// Khác null khi tài khoản đã gắn Google (đăng nhập Google ít nhất một lần).
  final String? googleUid;
  final String preferredLanguage;
  final bool notificationsEnabled;

  /// Tài khoản mới đăng ký chưa có họ tên — lấy tạm phần trước @ để card hồ sơ
  /// không hiện chuỗi rỗng.
  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  /// Google không cho số điện thoại nên tài khoản Google phải tự nhập thêm
  /// trước khi dùng app. Tài khoản email đã nhập số lúc đăng ký nên không hỏi.
  bool get needsPhone =>
      googleUid != null && (phone == null || phone!.trim().isEmpty);
}

/// Trạng thái đăng nhập dùng chung toàn app, chạy trên `/auth` của
/// smartheritage-BE (JWT + refresh token).
///
/// App cho phép khách (guest) duyệt tự do. Chỉ các tính năng có lưu dữ liệu để
/// theo dõi — yêu thích, lịch sử tham quan, hồ sơ cá nhân — mới yêu cầu đăng nhập.
class AuthController extends ChangeNotifier {
  AuthController({ApiClient? api}) : _api = api ?? ApiClient.instance {
    // Refresh token chết (hết hạn hoặc bị thu hồi) → về khách ngay, không để
    // UI đứng ở trạng thái "đã đăng nhập" mà mọi request đều 401.
    _api.onSessionExpired = _clearSession;
  }

  static AuthController _instance = AuthController();

  static AuthController get instance => _instance;

  /// Thay controller dùng chung bằng bản chạy trên ApiClient giả, để widget
  /// test dựng được luồng đăng nhập/đăng xuất mà không cần máy chủ thật.
  @visibleForTesting
  static set instance(AuthController controller) => _instance = controller;

  final ApiClient _api;

  AppUser? _user;
  bool _busy = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Đang gọi mạng cho đăng nhập/đăng ký — dùng để khoá nút và hiện spinner.
  bool get isBusy => _busy;

  String get name => _user?.displayName ?? appStrings.guest;
  String get email => _user?.email ?? '';

  /// Khôi phục phiên lúc mở app: có refresh token đã lưu thì hỏi lại `/auth/me`.
  ///
  /// Nuốt mọi lỗi — mở app khi mất mạng thì vào chế độ khách, không phải màn
  /// hình lỗi. Access token hết hạn sẽ được [ApiClient] tự làm mới.
  Future<void> restoreSession() async {
    await TokenStore.instance.load();
    if (!TokenStore.instance.hasSession) return;
    try {
      final data = await _api.get('/auth/me');
      if (data is Map<String, dynamic>) {
        _user = AppUser.fromJson(data);
        notifyListeners();
        await FavoriteRepository.instance.load();
      }
    } on ApiException {
      // Token hỏng đã được ApiClient dọn; lỗi mạng thì để lần sau thử lại.
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setBusy(true);
    try {
      final data = await _api.post('/auth/login', body: {
        'email': email.trim(),
        'password': password,
      });
      await _applyTokens(data);
    } finally {
      _setBusy(false);
    }
  }

  /// Đăng nhập bằng Google: lấy Firebase ID token rồi đổi lấy phiên của
  /// backend qua `POST /auth/google` (backend tự tạo tài khoản, hoặc gắn vào
  /// tài khoản đã đăng ký cùng email).
  ///
  /// Trả về `false` khi người dùng huỷ màn chọn tài khoản.
  Future<bool> signInWithGoogle() async {
    _setBusy(true);
    try {
      final idToken = await GoogleAuth.instance.signIn();
      if (idToken == null) return false;
      try {
        final data = await _api.post('/auth/google', body: {'idToken': idToken});
        await _applyTokens(data);
      } on ApiException catch (e) {
        // Lời nhắn của backend là tiếng Anh, viết cho dev — đổi các mã của
        // riêng luồng Google sang câu người dùng hiểu được.
        throw switch (e.statusCode) {
          401 => ApiException(appStrings.googleAccountRejected, statusCode: 401),
          503 => ApiException(appStrings.googleLoginDisabled, statusCode: 503),
          _ => e,
        };
      }
      return true;
    } finally {
      _setBusy(false);
    }
  }

  /// Đăng ký rồi đăng nhập luôn — `POST /auth/register` trả về user chứ không
  /// trả token, nên phải gọi tiếp `/auth/login` mới có phiên.
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setBusy(true);
    try {
      await _api.post('/auth/register', body: {
        'email': email.trim(),
        'password': password,
      });
      final data = await _api.post('/auth/login', body: {
        'email': email.trim(),
        'password': password,
      });
      await _applyTokens(data);
      final name = fullName?.trim();
      if (name != null && name.isNotEmpty) {
        await updateProfile(fullName: name);
      }
    } finally {
      _setBusy(false);
    }
  }

  /// Cập nhật hồ sơ qua `PATCH /auth/me`. Chỉ gửi những trường được truyền.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    String? preferredLanguage,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (gender != null) body['gender'] = gender;
    if (preferredLanguage != null) {
      body['preferredLanguage'] = preferredLanguage;
    }
    if (body.isEmpty) return;

    final data = await _api.patch('/auth/me', body: body);
    if (data is Map<String, dynamic>) {
      _user = AppUser.fromJson(data);
      notifyListeners();
    }
  }

  /// Đăng xuất. Thu hồi refresh token phía server nếu gọi được, nhưng trạng
  /// thái local luôn bị xoá — người dùng bấm đăng xuất thì phải ra, kể cả khi
  /// đang mất mạng.
  Future<void> logout() async {
    final refreshToken = TokenStore.instance.refreshToken;
    _clearSession();
    // Không chờ: plugin Google treo thì người dùng vẫn phải ra được.
    unawaited(GoogleAuth.instance.signOut());
    if (refreshToken == null) return;
    try {
      await _api.post('/auth/logout', body: {'refreshToken': refreshToken});
    } on ApiException {
      // Bỏ qua: token sẽ tự hết hạn.
    }
    await TokenStore.instance.clear();
  }

  Future<void> _applyTokens(dynamic data) async {
    if (data is! Map<String, dynamic>) {
      throw ApiException(appStrings.invalidServerData);
    }
    await TokenStore.instance.save(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    final rawUser = data['user'];
    if (rawUser is Map<String, dynamic>) {
      _user = AppUser.fromJson(rawUser);
    }
    notifyListeners();
    // Yêu thích thuộc về tài khoản — có phiên rồi mới kéo về được.
    await FavoriteRepository.instance.load();
  }

  void _clearSession() {
    if (_user == null) return;
    _user = null;
    // Dữ liệu của người vừa đăng xuất không được ở lại cho người sau thấy.
    FavoriteRepository.instance.clear();
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  /// Dựng sẵn một phiên cho widget test, không đụng tới mạng hay token.
  @visibleForTesting
  void setTestSession({
    String id = 'test-user',
    String email = 'lenhatanh2411@gmail.com',
    String fullName = 'Lê Nhật Anh',
    String? phone,
    String? googleUid,
  }) {
    _user = AppUser(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      googleUid: googleUid,
    );
    notifyListeners();
  }

  /// Xoá phiên trong test mà không gọi `/auth/logout`.
  @visibleForTesting
  void resetForTest() => _clearSession();

  /// Đảm bảo khách đã đăng nhập trước khi dùng tính năng lưu dữ liệu.
  ///
  /// Nếu chưa đăng nhập sẽ mở màn hình đăng nhập. Trả về `true` khi đã (hoặc
  /// vừa) đăng nhập thành công, `false` nếu khách huỷ.
  ///
  /// Đã đăng nhập Google mà chưa có số điện thoại (vd. tắt app giữa chừng ở
  /// màn nhập số — phiên đã lưu từ trước) thì bắt nhập nốt ở đây.
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (instance.isLoggedIn) return CompletePhoneScreen.ensure(context);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return result ?? instance.isLoggedIn;
  }
}
