import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen.dart';
import 'package:smartheritage/state/audio_player_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/app_sidebar.dart';

import 'support/fake_audio_player.dart';

Widget _harness() {
  return const MaterialApp(
    home: Scaffold(drawer: AppSidebar(), body: HomeScreen()),
  );
}

void main() {
  final scan = BeaconScanController.instance;
  late AudioPlayerController audio;

  /// Chỉ một hiện vật trong kho: beacon mock và test luôn nói về cùng một hiện
  /// vật, không phải đoán xem mock đang bắt con nào.
  final artifact = MockData.artifacts.first;

  /// Đồng hồ giả — `tester.pump` đẩy thời gian của framework chứ không đụng
  /// tới [DateTime.now], mà logic chống báo trùng lại đo bằng đồng hồ thật.
  late DateTime now;

  setUp(() {
    scan.stopScan();
    now = DateTime(2026, 9, 19, 10);
    scan.clockForTest = () => now;
    audio = AudioPlayerController(player: FakeAudioPlayer());
    AudioPlayerController.instance = audio;
    ArtifactRepository.instance.setArtifactsForTest([artifact]);
  });

  tearDown(() {
    scan.stopScan();
    scan.resetClockForTest();
    audio.close();
    ArtifactRepository.instance.resetForTest();
  });

  testWidgets('đứng yên cạnh beacon chỉ bật sheet một lần', (tester) async {
    await tester.pumpWidget(_harness());

    scan.startScan();
    await tester.pump();
    // Qua mốc phát hiện đầu tiên rồi đứng nguyên đó thêm nửa phút: beacon bắn
    // cả chục nhịp ranging trong quãng này.
    await tester.pump(const Duration(seconds: 35));
    await tester.pumpAndSettle();

    expect(find.byType(BeaconDetectedSheet), findsOneWidget);

    await tester.ensureVisible(find.text('Để sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.byType(BeaconDetectedSheet), findsNothing);

    // Vẫn chưa đi đâu cả — sheet không được phép bật lại.
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.byType(BeaconDetectedSheet), findsNothing);

    scan.stopScan();
    await tester.pump();
  });

  testWidgets('đi khỏi rồi quay lại thì được báo lại', (tester) async {
    await tester.pumpWidget(_harness());

    scan.startScan();
    await tester.pump();
    scan.onBeaconSeen(artifact);
    await tester.pumpAndSettle();
    expect(find.byType(BeaconDetectedSheet), findsOneWidget);

    await tester.ensureVisible(find.text('Để sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    // Khách đi sang khu khác: không có nhịp tín hiệu nào trong 6 phút.
    now = now.add(const Duration(minutes: 6));
    scan.onBeaconSeen(artifact);
    await tester.pumpAndSettle();

    expect(find.byType(BeaconDetectedSheet), findsOneWidget);

    scan.stopScan();
    await tester.pump();
  });

  testWidgets('mất sóng chập chờn không tính là đã rời đi', (tester) async {
    await tester.pumpWidget(_harness());

    scan.startScan();
    await tester.pump();
    scan.onBeaconSeen(artifact);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Để sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    // Đứng ở ranh giới vùng sóng: đứt hơn một phút rồi bắt lại, nhưng lần báo
    // trước mới cách đây hai phút nên cooldown vẫn phải chặn.
    now = now.add(const Duration(minutes: 2));
    scan.onBeaconSeen(artifact);
    await tester.pumpAndSettle();

    expect(find.byType(BeaconDetectedSheet), findsNothing);

    scan.stopScan();
    await tester.pump();
  });
}
