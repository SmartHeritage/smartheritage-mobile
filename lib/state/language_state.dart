import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/artifact_repository.dart';
import '../services/api_client.dart';
import 'auth_state.dart';

/// Ngôn ngữ nội dung khách đang dùng.
///
/// Backend chọn nội dung theo thứ tự: `?language=` trên request, rồi tới
/// `preferredLanguage` của tài khoản. App gửi `?language=` cho mọi khách (kể
/// cả chưa đăng nhập), còn khi đã đăng nhập thì ghi thêm vào tài khoản để máy
/// khác cũng nhận đúng ngôn ngữ.
class LanguageController extends ChangeNotifier {
  LanguageController._();

  static final LanguageController instance = LanguageController._();

  static const _key = 'visitor.language';
  static const defaultCode = 'vi';

  /// Nhãn hiển thị cho các mã quen thuộc. Mã lạ (admin vừa thêm vào Language
  /// Registry) vẫn chọn được, chỉ là hiện bằng chính mã đó.
  static const labels = <String, (String flag, String name, String sub)>{
    'vi': ('🇻🇳', 'Tiếng Việt', 'Vietnamese'),
    'en': ('🇬🇧', 'English', 'Tiếng Anh'),
    'fr': ('🇫🇷', 'Français', 'Tiếng Pháp'),
    'ja': ('🇯🇵', '日本語', 'Tiếng Nhật'),
    'ko': ('🇰🇷', '한국어', 'Tiếng Hàn'),
    'zh': ('🇨🇳', '中文', 'Tiếng Trung'),
  };

  String _code = defaultCode;
  bool _wasLoggedIn = false;
  AuthController? _auth;

  ArtifactRepository _repo = ArtifactRepository.instance;

  @visibleForTesting
  set repositoryForTest(ArtifactRepository repo) => _repo = repo;

  String get code => _code;

  /// Những ngôn ngữ hiện chọn được: theo backend nếu đã biết, không thì hai
  /// thứ tiếng app có sẵn bản dịch.
  List<String> get choices {
    final fromServer = _repo.availableLanguages;
    final codes = fromServer.isNotEmpty ? [...fromServer] : ['vi', 'en'];
    if (!codes.contains(_code)) codes.insert(0, _code);
    return codes;
  }

  /// Đọc lựa chọn đã lưu và gắn vào request hiện vật. Gọi trước lần tải
  /// hiện vật đầu tiên.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_key) ?? defaultCode;
    _repo.language = _code;
    _auth?.removeListener(_onAuthChanged);
    _auth = AuthController.instance..addListener(_onAuthChanged);
    _wasLoggedIn = false;
    _onAuthChanged();
  }

  /// Vừa đăng nhập: ngôn ngữ của tài khoản thắng lựa chọn trên máy.
  void _onAuthChanged() {
    final auth = AuthController.instance;
    final loggedIn = auth.isLoggedIn;
    if (loggedIn == _wasLoggedIn) return;
    _wasLoggedIn = loggedIn;
    final preferred = auth.user?.preferredLanguage;
    if (loggedIn && preferred != null && preferred != _code) {
      _apply(preferred);
    }
  }

  /// Khách chọn ngôn ngữ mới. Trả `false` nếu không lưu được vào tài khoản
  /// (lựa chọn trên máy vẫn được áp dụng).
  Future<bool> select(String code) async {
    if (code == _code) return true;
    await _apply(code);
    if (!AuthController.instance.isLoggedIn) return true;
    try {
      await AuthController.instance.updateProfile(preferredLanguage: code);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _apply(String code) async {
    _code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    _repo.language = code;
    await _repo.refresh();
  }
}
