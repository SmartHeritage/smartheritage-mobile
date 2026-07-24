import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';

/// Trạng thái đăng nhập dùng chung toàn app (mock, chưa gắn backend thật).
///
/// App cho phép khách (guest) duyệt tự do. Chỉ các tính năng có lưu dữ liệu để
/// theo dõi — yêu thích, lịch sử tham quan, hồ sơ cá nhân — mới yêu cầu đăng nhập.
class AuthController extends ChangeNotifier {
  AuthController._();

  static final AuthController instance = AuthController._();

  bool _isLoggedIn = false;
  String _name = 'Khách';
  String _email = '';

  bool get isLoggedIn => _isLoggedIn;
  String get name => _name;
  String get email => _email;

  void login({
    String name = 'Lê Nhật Anh',
    String email = 'lenhatanh2411@gmail.com',
  }) {
    _isLoggedIn = true;
    _name = name;
    _email = email;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _name = 'Khách';
    _email = '';
    notifyListeners();
  }

  /// Đảm bảo khách đã đăng nhập trước khi dùng tính năng lưu dữ liệu.
  ///
  /// Nếu chưa đăng nhập sẽ mở màn hình đăng nhập. Trả về `true` khi đã (hoặc
  /// vừa) đăng nhập thành công, `false` nếu khách huỷ.
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (instance.isLoggedIn) return true;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return result ?? instance.isLoggedIn;
  }
}
