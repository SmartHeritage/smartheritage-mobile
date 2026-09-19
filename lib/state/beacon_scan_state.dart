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

  /// Beacon bắt được khách sau vài giây kể từ lúc bật quét.
  static const Duration _firstSighting = Duration(seconds: 4);

  /// Beacon thật bắn tín hiệu đều đặn suốt thời gian khách còn đứng trong vùng
  /// sóng, nên mock cũng lặp — có vậy phần chống báo trùng mới được chạy thật.
  static const Duration _rangingInterval = Duration(seconds: 2);

  /// Đứt tín hiệu lâu hơn chừng này thì coi như khách đã rời khỏi hiện vật.
  /// Để rộng tay vì sóng BLE chập chờn: người vẫn đứng yên mà mất vài nhịp
  /// ranging là chuyện thường.
  static const Duration awayThreshold = Duration(seconds: 60);

  /// Rời đi rồi quay lại vẫn phải cách lần báo trước chừng này mới báo tiếp.
  /// Chặn khách đứng ngay ranh giới vùng sóng: tín hiệu vào/ra liên tục thì
  /// riêng [awayThreshold] không đủ để im.
  static const Duration repeatCooldown = Duration(minutes: 5);

  bool _isScanning = false;
  Artifact? _detected;
  Timer? _timer;

  /// Lần gần nhất bắt được tín hiệu của từng hiện vật — dùng để biết khách còn
  /// đứng đó hay đã đi chỗ khác.
  final Map<String, DateTime> _lastSeenAt = {};

  /// Lần gần nhất đã bật sheet cho từng hiện vật.
  final Map<String, DateTime> _announcedAt = {};

  DateTime Function() _clock = DateTime.now;

  bool get isScanning => _isScanning;

  /// Hiện vật beacon vừa phát hiện, đang chờ màn hình mở sheet giới thiệu.
  /// Bên hiển thị phải gọi [consumeDetection] sau khi xử lý.
  Artifact? get detected => _detected;

  void startScan() {
    if (_isScanning) return;
    _isScanning = true;
    _timer?.cancel();
    _timer = Timer(_firstSighting, () {
      _mockSighting();
      _timer = Timer.periodic(_rangingInterval, (_) => _mockSighting());
    });
    notifyListeners();
  }

  void _mockSighting() {
    if (!_isScanning) return;
    final artifact = _pickArtifact();
    if (artifact == null) return;
    onBeaconSeen(artifact);
  }

  /// Một nhịp tín hiệu beacon của [artifact]. Đây là cửa vào duy nhất cho dữ
  /// liệu beacon — mock gọi nó, SDK thật sau này cũng chỉ cần gọi nó.
  ///
  /// Chỉ đẩy [detected] ở nhịp ĐẦU của một lần ghé: khách đứng nguyên đó thì
  /// mọi nhịp sau đều im, không thì bấm "Để sau" xong hai giây sheet lại bật
  /// lên. Báo lại chỉ khi vừa mất tín hiệu đủ lâu ([awayThreshold] — tức là
  /// khách đã đi khỏi rồi quay lại) vừa cách lần báo trước [repeatCooldown].
  void onBeaconSeen(Artifact artifact) {
    if (!_isScanning) return;
    final now = _clock();
    final lastSeen = _lastSeenAt[artifact.id];
    _lastSeenAt[artifact.id] = now;

    final announcedAt = _announcedAt[artifact.id];
    if (announcedAt != null) {
      final leftArea =
          lastSeen == null || now.difference(lastSeen) >= awayThreshold;
      if (!leftArea) return;
      if (now.difference(announcedAt) < repeatCooldown) return;
    }

    _announcedAt[artifact.id] = now;
    _detected = artifact;
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

  /// Tắt quét là chủ ý của khách nên coi như xong một phiên: bật lại thì hiện
  /// vật ngay cạnh được báo lại từ đầu, không phải chờ hết cooldown.
  void stopScan() {
    _timer?.cancel();
    _isScanning = false;
    _detected = null;
    _lastSeenAt.clear();
    _announcedAt.clear();
    notifyListeners();
  }

  void toggle() => _isScanning ? stopScan() : startScan();

  /// Xoá hiện vật đã phát hiện mà không notify — tránh vòng lặp rebuild khi
  /// bên gọi đang ở trong chính callback của listener.
  void consumeDetection() => _detected = null;

  /// Đồng hồ giả cho test: mô phỏng "đi khỏi rồi vài phút sau quay lại" mà
  /// không phải chờ thật. `tester.pump` chỉ đẩy thời gian của framework chứ
  /// không đụng tới [DateTime.now].
  @visibleForTesting
  set clockForTest(DateTime Function() clock) => _clock = clock;

  @visibleForTesting
  void resetClockForTest() => _clock = DateTime.now;
}
