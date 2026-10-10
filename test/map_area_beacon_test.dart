import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/config.dart';
import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/beacon_repository.dart';
import 'package:smartheritage/data/crowd_repository.dart';
import 'package:smartheritage/screens/map/attraction_map_screen.dart';
import 'package:smartheritage/screens/map/floor_plan_screen.dart';
import 'package:smartheritage/screens/map/map_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _artifact(
        String id, String attractionId, double lat, double lng) =>
    {
      'id': id,
      'name': 'Hiện vật $id',
      'attractionId': attractionId,
      'latitude': lat,
      'longitude': lng,
    };

/// Hai khu: Huế (chưa ghim toạ độ) có hai điểm tham quan, Hà Nội (đã ghim).
final _areas = [
  {'id': 'hue', 'name': 'Bảo tàng Huế', 'latitude': null, 'longitude': null},
  {'id': 'hn', 'name': 'Hoàng thành', 'latitude': 21.03, 'longitude': 105.84},
];
final _attractions = [
  {'id': 'hall', 'name': 'Hội trường', 'tourismAreaId': 'hue'},
  // Điểm trong nhà có sơ đồ tầng: chọn vào là mở sơ đồ, không zoom bản đồ.
  {'id': 'yard', 'name': 'Sân ngoài trời', 'tourismAreaId': 'hue',
   'mapType': 'INDOOR', 'floorPlanUrl': 'https://cdn.example/plan.png'},
  {'id': 'gate', 'name': 'Đoan Môn', 'tourismAreaId': 'hn'},
];
final _artifacts = [
  _artifact('a1', 'hall', 16.46, 107.57),
  _artifact('a2', 'hall', 16.48, 107.59),
  _artifact('a3', 'yard', 16.47, 107.58),
  _artifact('a4', 'gate', 21.03, 105.84),
];

Future<http.Response> _backend(http.Request req) async {
  final path = req.url.path;
  if (path.endsWith('/tourism-areas')) return _json(_areas);
  if (path.endsWith('/attractions')) return _json(_attractions);
  if (path.endsWith('/artifacts')) return _json(_artifacts);
  if (path.endsWith('/hall/map')) {
    return _json({
      'attraction': _attractions[0],
      'beacons': [
        {'id': 'b-hall', 'name': 'Beacon sảnh chính', 'attractionId': 'hall',
         'latitude': 16.47, 'longitude': 107.58, 'mapX': null, 'mapY': null},
        {'id': 'b-nopin', 'name': 'Beacon chưa ghim', 'attractionId': 'hall',
         'latitude': null, 'longitude': null},
      ],
      'artifacts': const [],
    });
  }
  if (path.endsWith('/yard/map')) return _json({'message': 'boom'}, 500);
  if (path.endsWith('/gate/map')) {
    return _json({
      'attraction': _attractions[2],
      'beacons': [
        {'id': 'b-gate', 'name': 'Beacon cổng', 'attractionId': 'gate',
         'latitude': 21.03, 'longitude': 105.84},
      ],
      'artifacts': const [],
    });
  }
  return _json(const []);
}

ApiClient _api() => ApiClient(httpClient: MockClient(_backend), baseUrl: _base);

void main() {
  group('ArtifactRepository — khu du lịch', () {
    late ArtifactRepository repo;

    setUp(() async {
      repo = ArtifactRepository(api: _api());
      await repo.refresh();
    });

    test('nhóm hiện vật theo khu qua attraction', () {
      expect(repo.tourismAreas.map((a) => a.name),
          ['Bảo tàng Huế', 'Hoàng thành']);
      expect(repo.artifactsInArea('hue').map((a) => a.id), ['a1', 'a2', 'a3']);
      expect(repo.artifactsInArea('hn').map((a) => a.id), ['a4']);
      expect(repo.artifactsInArea(null), hasLength(4));
    });
  });

  group('BeaconScanController.currentZone', () {
    final scan = BeaconScanController.instance;
    late DateTime now;
    const zone = BeaconCandidate(
      identity: BeaconIdentity(
          proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: 101),
      resolved: true,
      beaconId: 'b-hall',
      name: 'Beacon sảnh chính',
      artifactIds: ['a1', 'a2'],
    );

    setUp(() {
      now = DateTime(2026, 10, 9, 10);
      scan.stopScan();
      scan.clockForTest = () => now;
      BeaconRepository.instance = BeaconRepository(api: _api());
    });

    tearDown(() {
      scan.stopScan();
      scan.resetClockForTest();
    });

    testWidgets('bắt được beacon thì thành vùng hiện tại, mất tín hiệu thì hết',
        (tester) async {
      final repo = ArtifactRepository(api: _api());
      await tester.runAsync(repo.refresh);
      scan.startScan();

      scan.onBeaconSeen(repo.tryById('a1')!, beacon: zone);
      expect(scan.currentZone?.name, 'Beacon sảnh chính');

      now = now.add(BeaconScanController.awayThreshold);
      expect(scan.currentZone, isNull);

      scan.stopScan();
    });
  });

  group('MapScreen', () {
    final scan = BeaconScanController.instance;
    late ArtifactRepository original;

    setUp(() async {
      original = ArtifactRepository.instance;
      scan.stopScan();
      BeaconRepository.instance = BeaconRepository(api: _api());
      ArtifactRepository.instance = ArtifactRepository(api: _api());
    });

    tearDown(() {
      scan.stopScan();
      ArtifactRepository.instance = original;
    });

    Future<void> open(WidgetTester tester) async {
      await tester.runAsync(ArtifactRepository.instance.refresh);
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('tab Bản đồ là danh sách khu vực, chưa có bản đồ',
        (tester) async {
      await open(tester);

      expect(find.text('Bảo tàng Huế'), findsOneWidget);
      expect(find.text('Chọn một khu vực để xem bản đồ'), findsOneWidget);
      expect(find.text('Hội trường'), findsOneWidget);
      expect(find.text('2 hiện vật · Bản đồ'), findsOneWidget);
      expect(find.text('Sân ngoài trời'), findsOneWidget);
      expect(find.text('1 hiện vật · Sơ đồ tầng'), findsOneWidget);
      // Khu du lịch khác không lẫn vào.
      expect(find.text('Đoan Môn'), findsNothing);
      expect(find.byType(AttractionMapScreen), findsNothing);
    });

    testWidgets('bấm khu ngoài trời thì mở bản đồ của khu đó', (tester) async {
      await open(tester);

      await tester.tap(find.text('Hội trường'));
      await tester.pumpAndSettle();

      expect(find.byType(AttractionMapScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Hội trường'), findsOneWidget);
      expect(find.text('Hiện vật a1'), findsOneWidget);
      expect(find.text('Hiện vật a2'), findsOneWidget);
      // Hiện vật của khu khác không lẫn vào.
      expect(find.text('Hiện vật a3'), findsNothing);
      // Beacon đã ghim toạ độ mới có ghim.
      expect(find.text('Beacon sảnh chính'), findsOneWidget);
      expect(find.text('Beacon chưa ghim'), findsNothing);

      // Bấm ghim hiện vật → thẻ thông tin ở đáy.
      await tester.tap(find.text('Hiện vật a1'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Chọn một khu vực để xem bản đồ'), findsOneWidget);
    });

    testWidgets('bấm khu trong nhà có sơ đồ tầng thì mở sơ đồ tầng',
        (tester) async {
      await open(tester);

      await tester.tap(find.text('Sân ngoài trời'));
      await tester.pumpAndSettle();

      expect(find.byType(FloorPlanScreen), findsOneWidget);
      expect(find.byType(AttractionMapScreen), findsNothing);
    });

    testWidgets('đổi khu du lịch ở tiêu đề', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoàng thành').last);
      await tester.pumpAndSettle();

      expect(find.text('Đoan Môn'), findsOneWidget);
      expect(find.text('Hội trường'), findsNothing);
    });

    testWidgets('đứng trong vùng beacon: đánh dấu khu, bản đồ hiện dải',
        (tester) async {
      await open(tester);
      expect(find.text('Bạn đang ở đây'), findsNothing);

      scan.startScan();
      scan.onBeaconSeen(
        ArtifactRepository.instance.tryById('a1')!,
        beacon: const BeaconCandidate(
          identity: BeaconIdentity(
              proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: 101),
          resolved: true,
          beaconId: 'b-hall',
          name: 'Beacon sảnh chính',
          artifactIds: ['a1', 'a2'],
        ),
      );
      await tester.pump();

      // Đúng khu chứa beacon được đánh dấu.
      expect(find.text('Bạn đang ở đây'), findsOneWidget);

      await tester.tap(find.text('Hội trường'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đang ở khu vực Beacon sảnh chính'), findsOneWidget);

      scan.stopScan();
      await tester.pump();
    });
  });

  test('CrowdRepository.forBeacon đọc theo beaconId', () async {
    final repo = CrowdRepository(
      api: ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async => _json([
              {
                'beaconId': 'b-hall',
                'beaconName': 'Beacon sảnh chính',
                'activeDeviceCount': 6,
                'observationType': 'BEACON_ZONE',
                'artifactIds': ['a1', 'a2'],
              },
            ])),
      ),
    );

    await repo.refresh();

    expect(repo.forBeacon('b-hall')?.activeDevices, 6);
  });
}
