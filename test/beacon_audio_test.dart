import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen.dart';
import 'package:smartheritage/state/audio_player_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/app_sidebar.dart';
import 'package:smartheritage/widgets/mini_player_bar.dart';

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
/// chạy, mà ticker audio là Timer.periodic.
Future<void> _stopAll(WidgetTester tester) async {
  AudioPlayerController.instance.close();
  BeaconScanController.instance.stopScan();
  await tester.pump();
}

void main() {
  final audio = AudioPlayerController.instance;
  final scan = BeaconScanController.instance;

  setUp(() {
    scan.stopScan();
    audio.close();
    audio.isMuted = false;
  });

  tearDown(() {
    scan.stopScan();
    audio.close();
  });

  testWidgets('beacon phát hiện thì tự phát thuyết minh', (tester) async {
    await tester.pumpWidget(_harness());

    expect(audio.artifact, isNull);

    await _triggerDetection(tester);

    // MockData.artifacts[1] là hiện vật beacon mock phát hiện.
    expect(audio.artifact?.id, MockData.artifacts[1].id);
    expect(audio.isPlaying, isTrue);
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

  testWidgets('trạng thái tắt tiếng giữ qua các hiện vật', (tester) async {
    await tester.pumpWidget(_harness());
    audio.isMuted = true;

    await _triggerDetection(tester);

    // Phát hiện mới vẫn im lặng, không tự bật tiếng lại.
    expect(audio.artifact?.id, MockData.artifacts[1].id);
    expect(audio.isMuted, isTrue);
    expect(find.text('Thuyết minh đang tắt tiếng'), findsOneWidget);

    await _stopAll(tester);
  });
}
