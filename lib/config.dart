import 'package:flutter/foundation.dart';

/// Cấu hình điểm cuối backend (smartheritage-BE).
///
/// Đổi khi chạy máy thật hoặc server khác:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1`
class AppConfig {
  AppConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Backend mặc định chạy ở cổng 3000 với route prefix `/api/v1`.
  ///
  /// iOS simulator và desktop dùng chung network stack với máy chủ nên gọi
  /// thẳng `localhost`. Android emulator thì `localhost` là chính máy ảo —
  /// host nằm ở `10.0.2.2`. Máy thật phải truyền `--dart-define` vì không có
  /// giá trị nào đoán được IP của máy dev trong mạng LAN.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  /// Thời gian chờ tối đa cho một request.
  static const Duration requestTimeout = Duration(seconds: 10);
}
