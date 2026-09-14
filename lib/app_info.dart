/// Thông tin định danh ứng dụng.
///
/// Sửa cùng lúc với `version:` trong pubspec.yaml — chưa dùng
/// package_info_plus nên giá trị này không tự đọc từ pubspec.
class AppInfo {
  AppInfo._();

  static const String version = '1.0.0';

  /// Dạng hiển thị cho UI.
  static const String versionLabel = 'v$version';
}
