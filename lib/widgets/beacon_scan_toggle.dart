import 'package:flutter/material.dart';

import '../state/auth_state.dart';
import '../state/beacon_scan_state.dart';
import '../theme/app_theme.dart';

/// Bật/tắt quét iBeacon từ một nút trên giao diện, và báo cho khách khi bật
/// không được (Bluetooth tắt, chưa cấp quyền vị trí…).
///
/// Dùng chung cho mọi công tắc quét (trang chủ, trang cá nhân, sidebar) để
/// chỗ nào bật cũng báo lỗi giống nhau.
///
/// Bật quét phải đăng nhập (2026-10-21); tắt thì không cần.
Future<void> toggleBeaconScan(BuildContext context) async {
  // Lấy trước khi chờ: bật quét có thể mở hộp thoại xin quyền, lúc quay lại
  // widget đã có thể bị gỡ.
  final messenger = ScaffoldMessenger.of(context);
  if (!BeaconScanController.instance.isScanning &&
      !await AuthController.ensureLoggedIn(context)) {
    return;
  }
  final error = await BeaconScanController.instance.toggle();
  if (error == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(errorSnackBar(error));
}
