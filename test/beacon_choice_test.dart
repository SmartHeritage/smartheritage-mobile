import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/config.dart';
import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/beacon_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/ibeacon_scanner.dart';
import 'package:smartheritage/state/audio_player_state.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/theme/app_theme.dart';
import 'package:smartheritage/widgets/beacon_choice_sheet.dart';

import 'support/fake_audio_player.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

HeardBeacon _heard(int minor) => HeardBeacon(
  identity: BeaconIdentity(
    proximityUuid: AppConfig.demoProximityUuid,
    major: 1,
    minor: minor,
  ),
  distanceMeters: 1.5,
  rssi: -60,
);

/// Bluetooth giả: test tự đẩy từng nhịp quét qua [emit].
class _FakeSource implements BeaconSource {
  void Function(List<HeardBeacon>)? _onHeard;

  @override
  Future<String?> start(void Function(List<HeardBeacon>) onHeard) async {
    _onHeard = onHeard;
    return null;
  }

  @override
  Future<void> stop() async {}

  void emit(List<HeardBeacon> heard) => _onHeard?.call(heard);
}

void main() {
  final scan = BeaconScanController.instance;
  late _FakeSource source;
  late List<Map<String, dynamic>> scans;
  late FakeAudioPlayer player;
  late AudioPlayerController audio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    scans = [];
    scan.stopScan();
    BeaconScanController.askToChoose = true;
    source = _FakeSource();
    scan.sourceForTest = source;
    player = FakeAudioPlayer();
    audio = AudioPlayerController(player: player);
    AudioPlayerController.instance = audio;
    AuthController.instance.setTestSession();
    ArtifactRepository.instance.setArtifactsForTest([
      Artifact.fromJson({'id': 'uuid-1', 'name': 'Trống đồng Đông Sơn'}),
      Artifact.fromJson({
        'id': 'uuid-2',
        'name': 'Ấn vàng triều Nguyễn',
        'audioUrl': 'https://cdn.example/an-vang.mp3',
      }),
      Artifact.fromJson({
        'id': 'uuid-3',
        'name': 'Tượng Phật A Di Đà',
        'audioUrl': 'https://cdn.example/tuong-phat.mp3',
      }),
    ]);
    // 101 phục vụ hai hiện vật, 103 một hiện vật.
    BeaconRepository.instance = BeaconRepository(
      api: ApiClient(
        baseUrl: 'http://test.local/api/v1',
        httpClient: MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          if (req.url.path.endsWith('/scans')) {
            scans.add(body);
            return _json({'created': true}, 201);
          }
          return _json({
            'candidates': [
              for (final b in body['beacons'] as List)
                {
                  'resolved': true,
                  'beaconId': 'b-${b['minor']}',
                  'proximityUuid': AppConfig.demoProximityUuid,
                  'major': 1,
                  'minor': b['minor'],
                  'name': 'Beacon ${b['minor']}',
                  'artifactIds': b['minor'] == 101
                      ? ['uuid-1', 'uuid-2']
                      : ['uuid-3'],
                },
            ],
          });
        }),
      ),
    );
  });

  tearDown(() {
    scan.stopScan();
    scan.sourceForTest = null;
    BeaconScanController.askToChoose = false;
    audio.close();
    AuthController.instance.resetForTest();
    ArtifactRepository.instance.resetForTest();
  });

  test(
    'beacon nhiều hiện vật: đưa danh sách, /scans chưa kèm hiện vật',
    () async {
      await scan.startScan();
      source.emit([_heard(101)]);
      await pumpEventQueue();

      expect(
        [for (final a in scan.detectedChoices) a.id],
        ['uuid-1', 'uuid-2'],
      );
      expect(scans.single['minor'], 101);
      expect(scans.single.containsKey('artifactId'), isFalse);

      // Khách chọn → gửi bổ sung kèm hiện vật để backend ghi lịch sử.
      scan.reportChoice(scan.detectedChoices.first);
      await pumpEventQueue();
      expect(scans.last['artifactId'], 'uuid-1');
      expect(scans.last['source'], 'beacon');
    },
  );

  test('beacon một hiện vật: giữ như cũ', () async {
    await scan.startScan();
    source.emit([_heard(103)]);
    await pumpEventQueue();

    expect(scan.detected?.id, 'uuid-3');
    expect(scan.detectedChoices, isEmpty);
    expect(scans.single['artifactId'], 'uuid-3');
  });

  test('bản V1 vẫn tự chọn hiện vật có thuyết minh', () async {
    BeaconScanController.askToChoose = false;
    await scan.startScan();
    source.emit([_heard(101)]);
    await pumpEventQueue();

    expect(scan.detected?.id, 'uuid-2');
    expect(scan.detectedChoices, isEmpty);
    expect(scans.single['artifactId'], 'uuid-2');
  });

  // Carousel trang chủ cũng có tên hiện vật — chỉ tìm trong popup.
  Finder inSheet(String text) => find.descendant(
    of: find.byType(BeaconChoiceSheet),
    matching: find.text(text),
  );

  Future<void> pumpHome(WidgetTester tester) async {
    // Rộng như test beacon cũ: font test (Ahem) rất to, khung 390pt làm tràn
    // chip/mini-player sẵn có — không phải lỗi của popup chọn.
    tester.view.physicalSize = const Size(800 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeScreenV2()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('trang chủ V2: hiện danh sách, không tự phát; chọn thì phát', (
    tester,
  ) async {
    await pumpHome(tester);
    await scan.startScan();
    source.emit([_heard(101)]);
    await tester.pumpAndSettle();

    expect(find.text('Có 2 hiện vật quanh đây'), findsOneWidget);
    expect(inSheet('Trống đồng Đông Sơn'), findsOneWidget);
    expect(audio.artifact, isNull);
    expect(player.lastUrl, isNull);

    await tester.tap(inSheet('Ấn vàng triều Nguyễn'));
    await tester.pumpAndSettle();

    expect(find.text('Có 2 hiện vật quanh đây'), findsNothing);
    expect(audio.artifact?.id, 'uuid-2');
    expect(player.lastUrl, contains('an-vang'));
    expect(find.text('Đang phát thuyết minh âm thanh'), findsOneWidget);
    expect(scans.last['artifactId'], 'uuid-2');

    audio.close();
    scan.stopScan();
    await tester.pump();
  });

  testWidgets('trang chủ V2: "Để sau" thì không phát gì', (tester) async {
    await pumpHome(tester);
    await scan.startScan();
    source.emit([_heard(101)]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(find.text('Có 2 hiện vật quanh đây'), findsNothing);
    expect(audio.artifact, isNull);
    expect(find.text('Đang phát thuyết minh âm thanh'), findsNothing);

    scan.stopScan();
    await tester.pump();
  });
}
