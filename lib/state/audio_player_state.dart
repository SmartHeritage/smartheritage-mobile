import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/mock_data.dart';
import '../l10n/l10n.dart';

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
      if (state.processingState == ProcessingState.completed) {
        // Đang nghe theo danh sách thì sang bài kế như app nhạc; hết danh sách
        // (hoặc nghe lẻ một hiện vật) thì quay về đầu và dừng như cũ.
        if (hasNext) {
          next();
        } else {
          _player.pause();
          _player.seek(Duration.zero);
        }
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

  /// Danh sách đang nghe lần lượt (tab Danh sách nghe). Rỗng = nghe lẻ một
  /// hiện vật, hết bài thì dừng.
  List<Artifact> queue = const [];

  int get _queueIndex =>
      queue.indexWhere((a) => a.id == artifact?.id);

  bool get hasNext {
    final i = _queueIndex;
    return i >= 0 && i < queue.length - 1;
  }

  bool get hasPrevious => _queueIndex > 0;

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

  /// Nghe lần lượt [items] bắt đầu từ bài thứ [index]. Bỏ sẵn các hiện vật
  /// chưa có bản thu để tự chuyển bài không vấp vào bài câm.
  Future<void> playQueue(List<Artifact> items, int index) {
    final start = items[index];
    queue = [
      for (final a in items)
        if (a.hasAudio) a,
    ];
    return play(start);
  }

  Future<void> next() async {
    final i = _queueIndex;
    if (i < 0 || i >= queue.length - 1) return;
    await play(queue[i + 1]);
  }

  /// Giống nút lùi của app nhạc: đã nghe quá vài giây thì về đầu bài, mới
  /// bắt đầu thì lùi hẳn về bài trước.
  Future<void> previous() async {
    final i = _queueIndex;
    if (i <= 0 || position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      notifyListeners();
      return;
    }
    await play(queue[i - 1]);
  }

  /// Mở bản thu của [next] rồi phát. Cùng hiện vật thì phát tiếp chứ không
  /// tải lại từ đầu.
  Future<void> play(Artifact next) async {
    // Mở một hiện vật ngoài danh sách (trang chi tiết, beacon) = thôi nghe
    // theo danh sách, khỏi hết bài lại nhảy sang bài của danh sách cũ.
    if (!queue.any((a) => a.id == next.id)) queue = const [];
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
      error = appStrings.audioNoRecording;
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
      error = appStrings.audioPlayFailed;
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
    queue = const [];
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
