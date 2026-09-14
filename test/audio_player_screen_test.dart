import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/audio/audio_player_screen.dart';
import 'package:smartheritage/state/audio_player_state.dart';

Widget _harness(Artifact artifact) {
  return MaterialApp(home: AudioPlayerScreen(artifact: artifact));
}

/// Dừng ngay trong test body: framework soát timer pending trước khi tearDown
/// chạy, mà ticker audio là Timer.periodic.
Future<void> _stop(WidgetTester tester) async {
  AudioPlayerController.instance.close();
  await tester.pump();
}

void main() {
  final audio = AudioPlayerController.instance;
  final artifact = MockData.artifacts.first; // Trống đồng Đông Sơn, 03:45

  setUp(() {
    audio.close();
    audio.isMuted = false;
    audio.speed = 1.0;
  });

  testWidgets('mở màn là tự phát hiện vật đang xem', (tester) async {
    await tester.pumpWidget(_harness(artifact));
    await tester.pump();

    expect(audio.artifact?.id, artifact.id);
    expect(audio.isPlaying, isTrue);
    expect(find.text('Thuyết minh âm thanh'), findsOneWidget);
    expect(find.text(artifact.name), findsOneWidget);
    expect(find.text('${artifact.era} · ${artifact.zone}'), findsOneWidget);

    await _stop(tester);
  });

  testWidgets('hiện thời gian đã chạy và còn lại', (tester) async {
    await tester.pumpWidget(_harness(artifact));
    await tester.pump();

    // Vừa mở: 0:00 đã chạy, còn lại đủ 3:45.
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('-3:45'), findsOneWidget);

    // Kéo tới giữa bài → 1:52 / -1:53 (03:45 = 225s, một nửa là 112.5s).
    audio.seek(0.5);
    await tester.pump();
    expect(find.text('1:52'), findsOneWidget);
    expect(find.text('-1:52'), findsOneWidget);

    await _stop(tester);
  });

  testWidgets('nút tốc độ quay vòng qua các mức', (tester) async {
    await tester.pumpWidget(_harness(artifact));
    await tester.pump();

    expect(find.text('1×'), findsOneWidget);

    await tester.tap(find.text('1×'));
    await tester.pump();
    expect(find.text('1.25×'), findsOneWidget);

    await tester.tap(find.text('1.25×'));
    await tester.pump();
    expect(find.text('1.5×'), findsOneWidget);

    // Hết mức thì quay về đầu danh sách.
    await tester.tap(find.text('1.5×'));
    await tester.pump();
    expect(find.text('0.75×'), findsOneWidget);

    await _stop(tester);
  });

  testWidgets('nút loa tắt tiếng nhưng không dừng phát', (tester) async {
    await tester.pumpWidget(_harness(artifact));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();

    expect(audio.isMuted, isTrue);
    expect(audio.isPlaying, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await _stop(tester);
  });

  testWidgets('card nội dung mở được toàn văn thuyết minh', (tester) async {
    await tester.pumpWidget(_harness(artifact));
    await tester.pump();

    expect(find.text('Nội dung thuyết minh'), findsOneWidget);

    await tester.tap(find.text('Nội dung thuyết minh'));
    await tester.pumpAndSettle();

    // Sheet toàn văn hiện tên hiện vật lần nữa → tổng cộng 2 chỗ.
    expect(find.text(artifact.name), findsNWidgets(2));

    await _stop(tester);
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

    await _stop(tester);
  });

  testWidgets('play/pause đổi icon', (tester) async {
    await tester.pumpWidget(_harness(artifact));
    await tester.pump();

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();

    expect(audio.isPlaying, isFalse);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await _stop(tester);
  });
}
