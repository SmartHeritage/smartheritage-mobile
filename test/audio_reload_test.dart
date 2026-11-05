import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/state/audio_player_state.dart';

import 'support/fake_audio_player.dart';

Artifact _withAudio(Artifact base, String audioUrl) => Artifact(
  id: base.id,
  name: base.name,
  era: base.era,
  zone: base.zone,
  shortIntro: base.shortIntro,
  description: base.description,
  icon: base.icon,
  gradient: base.gradient,
  rating: base.rating,
  reviewCount: base.reviewCount,
  audioDuration: base.audioDuration,
  videoDuration: base.videoDuration,
  imageAsset: base.imageAsset,
  audioUrl: audioUrl,
);

void main() {
  late FakeAudioPlayer player;
  late AudioPlayerController audio;
  final base = MockData.artifacts.first;

  setUp(() {
    player = FakeAudioPlayer();
    audio = AudioPlayerController(player: player);
  });

  tearDown(() => audio.dispose());

  test('admin thay bản thu rồi làm mới danh mục thì phát file mới', () async {
    await audio.play(_withAudio(base, 'http://h/uploads/audio/cu.mp3'));
    expect(player.lastUrl, 'http://h/uploads/audio/cu.mp3');

    // Cùng id, URL mới (vd. audio tạo bằng giọng máy thành bản chính).
    await audio.play(_withAudio(base, 'http://h/uploads/audio/moi.mp3'));
    expect(player.lastUrl, 'http://h/uploads/audio/moi.mp3');
    expect(audio.artifact!.audioUrl, 'http://h/uploads/audio/moi.mp3');
    expect(audio.isPlaying, isTrue);
  });

  test('cùng file thì phát tiếp, không nạp lại', () async {
    final a = _withAudio(base, 'http://h/uploads/audio/cu.mp3');
    await audio.play(a);
    player.emitPosition(const Duration(seconds: 30));
    await audio.play(a);
    expect(audio.position, const Duration(seconds: 30));
  });

  test('lần trước lỗi thì lần sau thử nạp lại', () async {
    final a = _withAudio(base, 'http://h/uploads/audio/cu.mp3');
    player.failOnLoad = true;
    await audio.play(a);
    expect(audio.error, isNotNull);

    player.failOnLoad = false;
    await audio.play(a);
    expect(audio.error, isNull);
    expect(player.lastUrl, 'http://h/uploads/audio/cu.mp3');
    expect(audio.isPlaying, isTrue);
  });
}
