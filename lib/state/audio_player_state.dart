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
