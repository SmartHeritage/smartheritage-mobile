import 'dart:async';

import 'package:flutter/material.dart';

import '../data/artifact_repository.dart';
import '../data/mock_data.dart';

/// Trạng thái quét iBeacon dùng chung toàn app (mock, chưa gắn SDK beacon thật).
///
/// Tách khỏi màn hình trang chủ để sidebar bật/tắt được cùng một trạng thái —
/// card trên trang chủ và công tắc trong sidebar luôn khớp nhau.
class BeaconScanController extends ChangeNotifier {
  BeaconScanController._();

  static final BeaconScanController instance = BeaconScanController._();

  bool _isScanning = false;
  Artifact? _detected;
  Timer? _timer;

  bool get isScanning => _isScanning;

  /// Hiện vật beacon vừa phát hiện, đang chờ màn hình mở sheet giới thiệu.
  /// Bên hiển thị phải gọi [consumeDetection] sau khi xử lý.
  Artifact? get detected => _detected;

  void startScan() {
    if (_isScanning) return;
    _isScanning = true;
    // Mô phỏng: khi đang quét, sau vài giây beacon phát hiện một hiện vật.
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      if (!_isScanning) return;
      // Lấy hiện vật thứ hai cho giống bản demo cũ, nhưng danh sách giờ đến từ
      // API nên không chắc có đủ phần tử.
      final all = ArtifactRepository.instance.artifacts;
      if (all.isEmpty) return;
      _detected = all.length > 1 ? all[1] : all.first;
      notifyListeners();
    });
    notifyListeners();
  }

  void stopScan() {
    _timer?.cancel();
    _isScanning = false;
    _detected = null;
    notifyListeners();
  }

  void toggle() => _isScanning ? stopScan() : startScan();

  /// Xoá hiện vật đã phát hiện mà không notify — tránh vòng lặp rebuild khi
  /// bên gọi đang ở trong chính callback của listener.
  void consumeDetection() => _detected = null;
}
