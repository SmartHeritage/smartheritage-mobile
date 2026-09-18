import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/mock_data.dart';

/// Trạng thái phát thuyết minh dùng chung toàn app.
///
/// Phát file thật do admin tải lên (`artifact.audioUrl`). Trước đây đây là một
/// [Timer] chỉ đẩy thanh tiến trình chạy — nhìn như đang phát nhưng không có
/// tiếng nào, nên audio tải lên từ web admin không bao giờ nghe được.
///
/// Giữ nguyên giao diện cũ (`progress` 0..1, `isPlaying`, `seek`…) để mini
/// player và màn hình thuyết minh không phải viết lại.
class AudioPlayerController extends ChangeNotifier {
  AudioPlayerController({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _sub = _player.playerStateStream.listen((state) {
      // Hết bài thì quay về đầu và dừng, giống hành vi cũ.
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      notifyListeners();
    });
    _posSub = _player.positionStream.listen((_) => notifyListeners());
    _durSub = _player.durationStream.listen((_) => notifyListeners());
  }

  static AudioPlayerController? _instance;

  /// Tạo trễ: dựng [AudioPlayer] là đụng platform channel, mà widget test nạp
  /// class này trước khi binding sẵn sàng thì nổ ngay lúc load file.
  static AudioPlayerController get instance =>
      _instance ??= AudioPlayerController();

  /// Cắm player giả cho test — không có seam này thì mọi test chạm tới màn
  /// thuyết minh đều phải có thiết bị thật.
  @visibleForTesting
  static set instance(AudioPlayerController controller) =>
      _instance = controller;

  final AudioPlayer _player;
  StreamSubscription<PlayerState>? _sub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  Artifact? artifact;

  /// Đang tải file về trước khi phát được.
  bool isLoading = false;

  /// Lời báo lỗi khi không mở được file (mất mạng, file hỏng, ATS chặn).
  String? error;

  bool get isPlaying => _player.playing;

  /// Độ dài thật của bản thu. Trong lúc chưa tải xong metadata thì tạm lấy
  /// `audioDuration` mà backend ghi sẵn, để thanh tiến trình không nhảy.
  Duration get duration =>
      _player.duration ?? parseDuration(artifact?.audioDuration ?? '');

  Duration get position => _player.position;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Khách tắt tiếng — audio vẫn chạy tiến trình, chỉ không phát ra loa.
  /// Giữ qua các lần phát nên tắt một lần là các hiện vật sau cũng im.
  bool isMuted = false;

  void toggleMute() {
    isMuted = !isMuted;
    _player.setVolume(isMuted ? 0 : 1);
    notifyListeners();
  }

  static const speedOptions = <double>[0.75, 1.0, 1.25, 1.5];

  double speed = 1.0;

  /// Bấm nút tốc độ là nhảy sang mức kế tiếp rồi quay vòng.
  void cycleSpeed() {
    final next = (speedOptions.indexOf(speed) + 1) % speedOptions.length;
    speed = speedOptions[next];
    _player.setSpeed(speed);
    notifyListeners();
  }

  /// Mở bản thu của [next] rồi phát. Cùng hiện vật thì phát tiếp chứ không
  /// tải lại từ đầu.
  Future<void> play(Artifact next) async {
    if (artifact?.id == next.id && _player.audioSource != null) {
      if (error != null) return;
      await _player.play();
      notifyListeners();
      return;
    }

    artifact = next;
    error = null;

    if (!next.hasAudio) {
      // Không có file thì dừng hẳn — thà nói "chưa có thuyết minh" còn hơn
      // chạy một thanh tiến trình rỗng như bản demo cũ.
      error = 'Hiện vật này chưa có bản thuyết minh.';
      await _player.stop();
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _player.setUrl(next.audioUrl!);
      await _player.setSpeed(speed);
      await _player.setVolume(isMuted ? 0 : 1);
      isLoading = false;
      notifyListeners();
      await _player.play();
    } catch (e) {
      isLoading = false;
      error = 'Không phát được bản thuyết minh.';
      notifyListeners();
    }
  }

  void togglePlay() {
    if (artifact == null || error != null) return;
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    notifyListeners();
  }

  /// [value] là tỉ lệ 0..1 để khớp với thanh trượt của màn hình.
  void seek(double value) {
    final total = duration;
    if (total <= Duration.zero) return;
    final clamped = value.clamp(0.0, 1.0);
    _player.seek(total * clamped);
    notifyListeners();
  }

  void close() {
    _player.stop();
    artifact = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// Đổi chuỗi "mm:ss" (hoặc "hh:mm:ss") của backend thành [Duration].
Duration parseDuration(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return Duration.zero;
  final numbers = parts.map((p) => int.tryParse(p.trim()) ?? 0).toList();
  if (numbers.length == 2) {
    return Duration(minutes: numbers[0], seconds: numbers[1]);
  }
  return Duration(
    hours: numbers[0],
    minutes: numbers[1],
    seconds: numbers[2],
  );
}
