import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Trạng thái phát audio dùng chung toàn app (mock, chưa gắn backend thật).
///
/// Cho phép thanh mini-player hiển thị xuyên suốt các màn hình và giữ đồng bộ
/// với tab "Âm thanh" trong trang chi tiết hiện vật.
class AudioPlayerController extends ChangeNotifier {
  AudioPlayerController._();

  static final AudioPlayerController instance = AudioPlayerController._();

  Artifact? artifact;
  bool isPlaying = false;
  double progress = 0; // 0..1
  Timer? _ticker;

  /// Khách tắt tiếng — audio vẫn chạy tiến trình, chỉ không phát ra loa.
  /// Giữ qua các lần phát nên tắt một lần là các hiện vật sau cũng im.
  bool isMuted = false;

  void toggleMute() {
    isMuted = !isMuted;
    notifyListeners();
  }

  static const speedOptions = <double>[0.75, 1.0, 1.25, 1.5];

  double speed = 1.0;

  /// Bấm nút tốc độ là nhảy sang mức kế tiếp rồi quay vòng.
  void cycleSpeed() {
    final next = (speedOptions.indexOf(speed) + 1) % speedOptions.length;
    speed = speedOptions[next];
    notifyListeners();
  }

  void play(Artifact next) {
    if (artifact?.id != next.id) {
      artifact = next;
      progress = 0;
    }
    isPlaying = true;
    _startTicker();
    notifyListeners();
  }

  void togglePlay() {
    if (artifact == null) return;
    isPlaying = !isPlaying;
    if (isPlaying) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
    notifyListeners();
  }

  void seek(double value) {
    progress = value.clamp(0, 1);
    notifyListeners();
  }

  void close() {
    _ticker?.cancel();
    artifact = null;
    isPlaying = false;
    progress = 0;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 300), (_) {
      progress += 0.004;
      if (progress >= 1) {
        progress = 0;
        isPlaying = false;
        _ticker?.cancel();
      }
      notifyListeners();
    });
  }
}
