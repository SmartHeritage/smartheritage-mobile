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
      final detected = _pickArtifact();
      if (detected == null) return;
      _detected = detected;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Hiện vật mà beacon mock "phát hiện".
  ///
  /// Ưu tiên hiện vật đã có bản thuyết minh: đây là đường duy nhất trong app
  /// tự động phát audio, nên rơi vào hiện vật chưa có bản thu thì không thử
  /// được luồng đó. Chưa hiện vật nào có audio thì giữ hành vi demo cũ — lấy
  /// hiện vật thứ hai.
  Artifact? _pickArtifact() {
    final all = ArtifactRepository.instance.artifacts;
    if (all.isEmpty) return null;
    for (final artifact in all) {
      if (artifact.hasAudio) return artifact;
    }
    return all.length > 1 ? all[1] : all.first;
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
