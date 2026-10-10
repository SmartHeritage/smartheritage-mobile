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

  /// iBeacon của khu di tích — phải khớp `DEMO_UUID`/`DEMO_MAJOR` và các
  /// minor trong `smartheritage-BE/src/database/seed-demo.ts`.
  ///
  /// iOS chỉ quét được những proximity UUID khai báo trước (CoreLocation), nên
  /// beacon thật dùng UUID khác thì phải thêm vào [beaconUuids].
  static const String demoProximityUuid =
      'f7826da6-4fa2-4e98-8024-bc5b71e0893e';
  static const int demoMajor = 1;
  static const List<int> demoMinors = [101, 102, 103, 104, 105];

  /// Các proximity UUID app lắng nghe. Mặc định là UUID demo; beacon thật
  /// phát UUID khác thì truyền khi build (nhiều UUID cách nhau dấu phẩy):
  /// `flutter run --dart-define=BEACON_UUIDS=<uuid1>,<uuid2>`
  static List<String> get beaconUuids {
    const raw = String.fromEnvironment('BEACON_UUIDS');
    final uuids = [
      for (final part in raw.split(','))
        if (_uuidPattern.hasMatch(part.trim())) part.trim(),
    ];
    return uuids.isEmpty ? const [demoProximityUuid] : uuids;
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Dùng bộ quét giả thay cho Bluetooth thật — để trình diễn khi không có
  /// beacon, hoặc chạy trên simulator (không có Bluetooth):
  /// `flutter run --dart-define=BEACON_MOCK=true`
  static const bool useMockBeacons = bool.fromEnvironment('BEACON_MOCK');

  /// Chỉ coi là "đang đứng cạnh" beacon khi khoảng cách ước lượng (mét) không
  /// quá giá trị này. Khoảng cách tính từ RSSI và txPower đã hiệu chỉnh của
  /// beacon nên sai số lớn — chỉnh theo thực tế lắp đặt:
  /// `flutter run --dart-define=BEACON_MAX_METERS=3`
  static double get beaconMaxMeters =>
      double.tryParse(const String.fromEnvironment('BEACON_MAX_METERS')) ??
      5.0;
}
