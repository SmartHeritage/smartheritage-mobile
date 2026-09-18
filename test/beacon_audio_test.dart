import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen.dart';
import 'package:smartheritage/state/audio_player_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/app_sidebar.dart';
import 'package:smartheritage/widgets/mini_player_bar.dart';

import 'support/fake_audio_player.dart';

/// Giống bố cục MainShell: HomeScreen là body, mini-player ở bottom bar.
Widget _harness() {
  return const MaterialApp(
    home: Scaffold(
      drawer: AppSidebar(),
      body: HomeScreen(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [MiniPlayerBar()],
      ),
    ),
  );
}

/// Bật quét rồi đẩy thời gian qua mốc 4s để beacon mock phát hiện hiện vật.
Future<void> _triggerDetection(WidgetTester tester) async {
  BeaconScanController.instance.startScan();
  await _triggerDetectionTick(tester);
}

/// Chỉ đẩy thời gian, dùng khi quét đã được bật bằng cách khác (công tắc trong
/// sidebar chẳng hạn).
Future<void> _triggerDetectionTick(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Dừng ngay trong test body: framework soát timer pending trước khi tearDown
/// chạy, mà beacon mock dùng Timer.
Future<void> _stopAll(WidgetTester tester) async {
  AudioPlayerController.instance.close();
  BeaconScanController.instance.stopScan();
  await tester.pump();
}

/// Bản sao của hiện vật mock, có thêm `audioUrl` như dữ liệu thật từ backend.
Artifact _withAudio(Artifact base, {String? audioUrl}) => Artifact(
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
  final scan = BeaconScanController.instance;
  late FakeAudioPlayer player;
  late AudioPlayerController audio;

  /// Giống dữ liệu thật: chỉ MỘT hiện vật có bản thu, và nó nằm cuối danh
  /// sách — không phải vị trí mà beacon mock từng lấy cứng (index 1).
  final withAudioId = MockData.artifacts.last.id;

  void seedRepository({required bool withAudio}) {
    ArtifactRepository.instance.setArtifactsForTest([
      for (final a in MockData.artifacts)
        _withAudio(a,
            audioUrl: withAudio && a.id == withAudioId
                ? 'http://localhost:3000/uploads/audio/${a.id}.mp3'
                : null),
    ]);
  }

  setUp(() {
    scan.stopScan();
    player = FakeAudioPlayer();
    audio = AudioPlayerController(player: player);
    AudioPlayerController.instance = audio;
    seedRepository(withAudio: true);
  });

  tearDown(() {
    scan.stopScan();
    audio.close();
    ArtifactRepository.instance.resetForTest();
  });

  testWidgets('beacon phát hiện thì tự phát thuyết minh', (tester) async {
    await tester.pumpWidget(_harness());

    expect(audio.artifact, isNull);

    await _triggerDetection(tester);

    // Beacon phải chọn hiện vật CÓ bản thu, không lấy cứng index 1 nữa —
    // không thì luồng tự phát chẳng bao giờ chạy được.
    expect(audio.artifact?.id, withAudioId);
    expect(audio.isPlaying, isTrue);
    // Và phải thật sự mở file, không chỉ nhích thanh tiến trình như bản cũ.
    expect(player.lastUrl, contains(withAudioId));
    // Sheet beacon hiện kèm trạng thái đang phát.
    expect(find.text('Đang phát thuyết minh âm thanh'), findsOneWidget);

    await _stopAll(tester);
  });

  testWidgets('tự phát không gây exception giữa lúc build', (tester) async {
    await tester.pumpWidget(_harness());
    await _triggerDetection(tester);

    expect(tester.takeException(), isNull);

    await _stopAll(tester);
  });

  testWidgets('nút tắt tiếng trong sheet đổi trạng thái', (tester) async {
    await tester.pumpWidget(_harness());
    await _triggerDetection(tester);

    await tester.ensureVisible(find.text('Tắt tiếng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tắt tiếng'));
    await tester.pumpAndSettle();

    expect(audio.isMuted, isTrue);
    expect(find.text('Thuyết minh đang tắt tiếng'), findsOneWidget);
    expect(find.text('Bật tiếng'), findsOneWidget);

    // Tắt tiếng không dừng phát, chỉ im lặng.
    expect(audio.isPlaying, isTrue);

    await tester.ensureVisible(find.text('Bật tiếng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bật tiếng'));
    await tester.pumpAndSettle();
    expect(audio.isMuted, isFalse);
    expect(find.text('Đang phát thuyết minh âm thanh'), findsOneWidget);

    await _stopAll(tester);
  });

  testWidgets('nút loa ở mini-player tắt/bật tiếng', (tester) async {
    await tester.pumpWidget(_harness());
    await _triggerDetection(tester);

    // Đóng sheet để thấy mini-player.
    await tester.ensureVisible(find.text('Để sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    expect(audio.isMuted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(find.text('Thuyết minh · đã tắt tiếng'), findsOneWidget);

    await _stopAll(tester);
  });

  testWidgets('bật quét từ sidebar: sheet hiện thì sidebar đã đóng',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(AppSidebar), findsOneWidget);

    // Bật quét ngay trong sidebar — sidebar vẫn mở, đúng chủ ý.
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(find.byType(AppSidebar), findsOneWidget);

    // Quá 4s → beacon phát hiện → sheet mở và sidebar phải tự đóng, không thì
    // sheet đè lên sidebar và đóng sheet xong vẫn thấy sidebar.
    await _triggerDetectionTick(tester);

    expect(find.byType(BeaconDetectedSheet), findsOneWidget);
    expect(find.byType(AppSidebar), findsNothing);

    await _stopAll(tester);
  });

  testWidgets('hiện vật chưa có bản thu: nói rõ, không giả vờ đang phát',
      (tester) async {
    seedRepository(withAudio: false);
    await tester.pumpWidget(_harness());

    await _triggerDetection(tester);

    // Sheet vẫn mở để khách đọc giới thiệu…
    expect(find.byType(BeaconDetectedSheet), findsOneWidget);
    // …nhưng không hứa suông là đang phát.
    expect(find.text('Hiện vật này chưa có bản thuyết minh'), findsOneWidget);
    expect(find.text('Đang phát thuyết minh âm thanh'), findsNothing);
    expect(player.lastUrl, isNull);
    expect(audio.isPlaying, isFalse);
    // Không có lựa chọn nào tốt hơn thì giữ hành vi demo cũ.
    expect(find.text(MockData.artifacts[1].name), findsWidgets);

    await _stopAll(tester);
  });

  testWidgets('trạng thái tắt tiếng giữ qua các hiện vật', (tester) async {
    await tester.pumpWidget(_harness());
    audio.isMuted = true;

    await _triggerDetection(tester);

    // Phát hiện mới vẫn im lặng, không tự bật tiếng lại.
    expect(audio.artifact?.id, withAudioId);
    expect(audio.isMuted, isTrue);
    expect(find.text('Thuyết minh đang tắt tiếng'), findsOneWidget);

    await _stopAll(tester);
  });
}
