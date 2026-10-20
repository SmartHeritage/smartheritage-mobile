import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Token Mapbox của bản build, truyền lúc build:
/// `--dart-define-from-file=mapbox.local.json` (file gitignored, dạng
/// `{"MAPBOX_TOKEN": "pk.…"}`) hoặc `--dart-define=MAPBOX_TOKEN=pk.…`.
///
/// Là public token (`pk.`) nên nằm trong app là bình thường, nhưng vẫn để
/// ngoài git để mỗi máy/môi trường dùng token riêng. Thiếu token thì màn bản
/// đồ báo "chưa sẵn sàng" thay vì hiện một bản đồ trống.
class MapboxConfig {
  MapboxConfig._();

  static const token = String.fromEnvironment('MAPBOX_TOKEN');

  static bool get isConfigured => token.isNotEmpty;

  /// Gọi một lần lúc khởi động, trước khi tạo bản đồ nào.
  static void init() {
    if (isConfigured) MapboxOptions.setAccessToken(token);
  }
}
