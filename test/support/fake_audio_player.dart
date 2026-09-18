import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// [AudioPlayer] giả cho widget test.
///
/// just_audio nói chuyện với platform channel nên không chạy được trong
/// `flutter test`. Bản giả này hiện thực đúng phần mà [AudioPlayerController]
/// dùng tới, và ghi lại URL đã mở để test khẳng định app gọi đúng file backend
/// trả về thay vì chỉ kiểm tra thanh tiến trình nhúc nhích.
class FakeAudioPlayer implements AudioPlayer {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  AudioSource? _source;

  /// URL cuối cùng được nạp — `null` nghĩa là chưa hề mở file nào.
  String? lastUrl;

  @override
  double volume = 1;

  @override
  double speed = 1;

  /// Bật lên để giả lập file hỏng, mất mạng hoặc bị ATS chặn.
  bool failOnLoad = false;

  /// Độ dài player đọc được từ file sau khi nạp. Đặt khác `audioDuration` của
  /// backend để kiểm tra bên nào thắng.
  Duration durationOnLoad = const Duration(minutes: 2, seconds: 17);

  /// Số lần [stop] được gọi, để phân biệt "dừng hẳn" với "tạm dừng".
  int stopCount = 0;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  bool get playing => _playing;

  @override
  Duration get position => _position;

  @override
  Duration? get duration => _duration;

  @override
  AudioSource? get audioSource => _source;

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    if (failOnLoad) throw PlayerException(404, 'không mở được', null);
    lastUrl = url;
    _source = AudioSource.uri(Uri.parse(url));
    _position = Duration.zero;
    _duration = durationOnLoad;
    _durationController.add(_duration);
    return _duration;
  }

  @override
  Future<void> play() async {
    _playing = true;
    _emitState();
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _emitState();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _playing = false;
    _position = Duration.zero;
    _emitState();
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    _position = position ?? Duration.zero;
    _positionController.add(_position);
  }

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
  }

  /// Đẩy vị trí phát tới [value] như thể audio đã chạy tới đó.
  void emitPosition(Duration value) {
    _position = value;
    _positionController.add(value);
  }

  void _emitState() => _stateController.add(
        PlayerState(_playing, ProcessingState.ready),
      );

  // Phần còn lại của AudioPlayer không được dùng tới.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
