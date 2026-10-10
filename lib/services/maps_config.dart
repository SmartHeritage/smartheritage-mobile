import 'package:flutter/services.dart';

/// Hỏi phía native đã nạp khoá Google Maps SDK chưa.
///
/// Thiếu khoá thì SDK iOS làm crash app ngay khi tạo bản đồ, còn Android chỉ
/// hiện một bản đồ trắng — nên màn bản đồ phải hỏi trước rồi mới vẽ. Khoá đặt
/// ở `android/local.properties` và `ios/Flutter/Secrets.xcconfig`
/// (`GOOGLE_MAPS_API_KEY=...`).
class MapsConfig {
  MapsConfig._();

  static const _channel = MethodChannel('smartheritage/maps');

  static Future<bool>? _configured;

  static Future<bool> isConfigured() => _configured ??= _ask();

  static Future<bool> _ask() async {
    try {
      return await _channel.invokeMethod<bool>('isConfigured') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
