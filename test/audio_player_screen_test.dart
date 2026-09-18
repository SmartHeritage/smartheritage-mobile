import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/audio/audio_player_screen.dart';
import 'package:smartheritage/state/audio_player_state.dart';

import 'support/fake_audio_player.dart';

const _audioUrl = 'http://localhost:3000/uploads/audio/thuyet-minh.mp3';

/// Hiện vật đã có bản thu do admin tải lên. MockData không mang `audioUrl`
/// nên phải dựng lại — đúng như dữ liệu thật từ `GET /artifacts` trả về.
Artifact _withAudio({String? audioUrl = _audioUrl}) {
  final base = MockData.artifacts.first; // Trống đồng Đông Sơn, 03:45
  return Artifact(
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
}

Widget _harness(Artifact artifact) =>
    MaterialApp(home: AudioPlayerScreen(artifact: artifact));

void main() {
  late FakeAudioPlayer player;
  late AudioPlayerController audio;
  final artifact = _withAudio();

  setUp(() {
    player = FakeAudioPlayer()
      // Khớp audioDuration của hiện vật để các mốc thời gian đọc được rõ ràng.
      ..durationOnLoad = const Duration(minutes: 3, seconds: 45);
    audio = AudioPlayerController(player: player);
    AudioPlayerController.instance = audio;
  });

  group('phát file thật', () {
    testWidgets('mở màn là nạp đúng URL backend trả về rồi phát',
        (tester) async {
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      // Điểm mấu chốt: trước đây màn này chỉ chạy một Timer, không mở file nào.
      expect(player.lastUrl, _audioUrl);
      expect(audio.artifact?.id, artifact.id);
      expect(audio.isPlaying, isTrue);
      expect(find.text('Thuyết minh âm thanh'), findsOneWidget);
      expect(find.text(artifact.name), findsOneWidget);
    });

    testWidgets('thời gian lấy theo độ dài thật của file', (tester) async {
      player.durationOnLoad = const Duration(minutes: 2, seconds: 17);
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      // audioDuration của backend ghi 03:45, nhưng file thật dài 2:17 —
      // player phải thắng, không thì thanh trượt lệch so với tiếng.
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('-2:17'), findsOneWidget);
    });

    testWidgets('kéo thanh trượt thì seek tới đúng mốc', (tester) async {
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      audio.seek(0.5);
      await tester.pumpAndSettle();

      // 03:45 = 225s, một nửa là 112.5s → 1:52.
      expect(player.position, const Duration(milliseconds: 112500));
      expect(find.text('1:52'), findsOneWidget);
    });

    testWidgets('play/pause tác động lên player chứ không chỉ đổi icon',
        (tester) async {
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      expect(player.playing, isFalse);
      expect(audio.isPlaying, isFalse);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('nút loa hạ âm lượng player, không dừng phát', (tester) async {
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();

      expect(player.volume, 0);
      expect(audio.isMuted, isTrue);
      expect(audio.isPlaying, isTrue);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });

    testWidgets('nút tốc độ quay vòng và đổi speed của player', (tester) async {
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      expect(find.text('1×'), findsOneWidget);

      await tester.tap(find.text('1×'));
      await tester.pumpAndSettle();
      expect(find.text('1.25×'), findsOneWidget);
      expect(player.speed, 1.25);

      await tester.tap(find.text('1.25×'));
      await tester.pumpAndSettle();
      expect(find.text('1.5×'), findsOneWidget);

      // Hết mức thì quay về đầu danh sách.
      await tester.tap(find.text('1.5×'));
      await tester.pumpAndSettle();
      expect(find.text('0.75×'), findsOneWidget);
      expect(player.speed, 0.75);
    });
  });

  group('hiện vật chưa có bản thu', () {
    final silent = _withAudio(audioUrl: null);

    testWidgets('nói rõ là chưa có, không mở file nào', (tester) async {
      await tester.pumpWidget(_harness(silent));
      await tester.pumpAndSettle();

      expect(find.text('Hiện vật này chưa có bản thuyết minh.'), findsOneWidget);
      expect(player.lastUrl, isNull);
      expect(audio.isPlaying, isFalse);
    });

    testWidgets('bấm nút phát không làm gì', (tester) async {
      await tester.pumpWidget(_harness(silent));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(audio.isPlaying, isFalse);
      expect(player.lastUrl, isNull);
    });
  });

  group('lỗi khi mở file', () {
    testWidgets('báo lỗi thay vì đứng im ở trạng thái đang tải',
        (tester) async {
      player.failOnLoad = true;
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      expect(find.text('Không phát được bản thuyết minh.'), findsOneWidget);
      expect(audio.isLoading, isFalse);
      expect(audio.isPlaying, isFalse);
    });
  });

  group('phần còn lại của màn hình', () {
    testWidgets('card nội dung mở được toàn văn thuyết minh', (tester) async {
      await tester.pumpWidget(_harness(artifact));
      await tester.pumpAndSettle();

      expect(find.text('Nội dung thuyết minh'), findsOneWidget);

      await tester.tap(find.text('Nội dung thuyết minh'));
      await tester.pumpAndSettle();

      // Sheet toàn văn hiện tên hiện vật lần nữa → tổng cộng 2 chỗ.
      expect(find.text(artifact.name), findsNWidgets(2));
    });

    testWidgets('mở thì trượt từ dưới lên, bấm mũi tên xuống thì trượt xuống',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context).push(AudioPlayerScreen.route(artifact)),
              child: const Text('mở'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('mở'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final screen = find.byType(AudioPlayerScreen);
      final viewportHeight = tester.getSize(find.byType(MaterialApp)).height;
      final enteringY = tester.getTopLeft(screen).dy;
      // Đang trượt lên: còn nằm dưới vị trí cuối nhưng đã vào trong viewport.
      expect(enteringY, greaterThan(0));
      expect(enteringY, lessThan(viewportHeight));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(screen).dy, 0);

      // Mũi tên xuống → pop → transition ngược, tức trượt xuống.
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.getTopLeft(screen).dy, greaterThan(0));

      await tester.pumpAndSettle();
      expect(screen, findsNothing);
    });
  });
}
