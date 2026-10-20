import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/config.dart';
import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/beacon_repository.dart';
import 'package:smartheritage/data/crowd_repository.dart';
import 'package:smartheritage/screens/map/area_attractions_screen.dart';
import 'package:smartheritage/screens/map/attraction_map_screen.dart';
import 'package:smartheritage/screens/map/floor_plan_screen.dart';
import 'package:smartheritage/screens/map/floor_screen.dart';
import 'package:smartheritage/screens/map/map_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/heritage_map.dart';

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
  {'id': 'hn', 'name': 'Hoàng thành', 'latitude': 21.03, 'longitude': 105.84,
   'address': '19C Hoàng Diệu, Ba Đình, Hà Nội',
   'description': 'Quần thể di tích gắn với lịch sử Thăng Long.',
   'imageUrl': 'http://localhost:3000/uploads/area-images/hn.jpg'},
];
final _attractions = [
  {'id': 'hall', 'name': 'Hội trường', 'tourismAreaId': 'hue'},
  // Điểm trong nhà có sơ đồ tầng: chọn vào là mở sơ đồ, không zoom bản đồ.
  {'id': 'yard', 'name': 'Sân ngoài trời', 'tourismAreaId': 'hue',
   'mapType': 'INDOOR', 'floorPlanUrl': 'https://cdn.example/plan.png'},
  // Khối vẽ trên bản đồ thật của tầng trệt (tầng không có ảnh sơ đồ).
  {'id': 'gate', 'name': 'Đoan Môn', 'tourismAreaId': 'hn', 'floorId': 'f-g',
   'boundary': {'type': 'Polygon', 'coordinates': [[
     [105.840, 21.030], [105.841, 21.030], [105.841, 21.031],
     [105.840, 21.030],
   ]]}},
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
  // Hoàng thành có hai tầng (sắp theo sortOrder, không theo thứ tự trả về);
  // Huế không có tầng → danh sách khu vực như cũ.
  if (path.endsWith('/tourism-areas/hn/floors')) {
    return _json([
      {'id': 'f-g', 'name': 'Tầng G', 'sortOrder': 2, 'floorPlanUrl': null},
      {'id': 'f-2', 'name': 'Tầng 2', 'sortOrder': 1,
       'floorPlanUrl': 'https://cdn.example/f2.png'},
    ]);
  }
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
  // Mức đông theo điểm: Hội trường có khách; Sân ngoài trời không có beacon
  // nên không đo được (không được hiện "vắng").
  if (path.endsWith('/hall/crowd')) {
    return _json({'attractionId': 'hall', 'attractionName': 'Hội trường',
        'activeDeviceCount': 3, 'beaconCount': 2, 'ttlSeconds': 300});
  }
  if (path.endsWith('/yard/crowd')) {
    return _json({'attractionId': 'yard', 'attractionName': 'Sân ngoài trời',
        'activeDeviceCount': 0, 'beaconCount': 0, 'ttlSeconds': 300});
  }
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
    late CrowdRepository originalCrowd;

    setUp(() async {
      original = ArtifactRepository.instance;
      originalCrowd = CrowdRepository.instance;
      scan.stopScan();
      BeaconRepository.instance = BeaconRepository(api: _api());
      ArtifactRepository.instance = ArtifactRepository(api: _api());
      CrowdRepository.instance = CrowdRepository(api: _api());
    });

    tearDown(() {
      scan.stopScan();
      ArtifactRepository.instance = original;
      CrowdRepository.instance = originalCrowd;
    });

    Future<void> openTab(WidgetTester tester) async {
      await tester.runAsync(ArtifactRepository.instance.refresh);
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pumpAndSettle();
    }

    /// Danh sách khu vực của một địa điểm (mở từ ghim trên tab Bản đồ).
    Future<void> open(WidgetTester tester, [String areaId = 'hue']) async {
      await tester.runAsync(ArtifactRepository.instance.refresh);
      final area = ArtifactRepository.instance.tourismAreas
          .firstWhere((a) => a.id == areaId);
      await tester.pumpWidget(
          MaterialApp(home: AreaAttractionsScreen(area: area)));
      await tester.pumpAndSettle();
    }

    testWidgets('tab Bản đồ là bản đồ mọi địa điểm đã có vị trí',
        (tester) async {
      await openTab(tester);

      // Bản đồ tràn màn, không thanh tiêu đề; nút danh sách nổi ở góc trên.
      expect(find.byType(AppBar), findsNothing);
      expect(find.byTooltip('Danh sách địa điểm'), findsOneWidget);
      // Chỉ địa điểm đã chấm vị trí mới có ghim.
      expect(find.byKey(const ValueKey('area:hn')), findsOneWidget);
      expect(find.byKey(const ValueKey('area:hue')), findsNothing);

      // Bấm ghim → thẻ địa điểm → mở danh sách khu vực của nó.
      await tester.tap(find.text('Hoàng thành'));
      await tester.pumpAndSettle();
      expect(find.text('1 khu vực · 1 hiện vật'), findsOneWidget);
      // Thẻ địa điểm: địa chỉ và mô tả admin nhập.
      expect(find.text('19C Hoàng Diệu, Ba Đình, Hà Nội'), findsOneWidget);
      expect(find.text('Quần thể di tích gắn với lịch sử Thăng Long.'),
          findsOneWidget);
      await tester.tap(find.text('Xem các khu vực'));
      await tester.pumpAndSettle();

      expect(find.byType(AreaAttractionsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Hoàng thành'), findsOneWidget);
      // Địa điểm có tầng: hiện tầng trước, chưa hiện khu vực.
      expect(find.text('Chọn tầng để xem sơ đồ khu vực'), findsOneWidget);
      expect(find.text('Tầng G'), findsOneWidget);
      expect(find.text('Đoan Môn'), findsNothing);
      expect(find.text('Hội trường'), findsNothing);
    });

    // Bản đồ giả trong test không kéo được — gọi thẳng callback cử chỉ.
    void dragMap(WidgetTester tester) =>
        tester.widget<HeritageMap>(find.byType(HeritageMap)).onUserMove!();

    testWidgets('tab Bản đồ: "Xem tất cả" chỉ hiện sau khi khách kéo/zoom',
        (tester) async {
      await openTab(tester);
      final fitAll = find.byTooltip('Xem tất cả');
      expect(fitAll, findsNothing);

      // Chọn ghim chỉ lia camera, chưa tính là rời khung.
      await tester.tap(find.text('Hoàng thành'));
      await tester.pumpAndSettle();
      expect(fitAll, findsNothing);

      dragMap(tester);
      await tester.pump();
      expect(fitAll, findsOneWidget);
      // Nút nằm trên thẻ, thẻ vẫn còn.
      expect(find.text('Xem các khu vực'), findsOneWidget);

      // Về khung ban đầu: đóng thẻ, ẩn nút.
      await tester.tap(fitAll);
      await tester.pumpAndSettle();
      expect(fitAll, findsNothing);
      expect(find.text('Xem các khu vực'), findsNothing);
    });

    testWidgets('chọn tầng rồi mới hiện sơ đồ khu vực của tầng đó',
        (tester) async {
      await open(tester, 'hn');

      // Đúng thứ tự admin xếp (sortOrder), kèm số khu vực và nền.
      final t2 = tester.getTopLeft(find.text('Tầng 2')).dy;
      final tg = tester.getTopLeft(find.text('Tầng G')).dy;
      expect(t2, lessThan(tg));
      expect(find.text('Chưa có khu vực · Sơ đồ tầng'), findsOneWidget);
      expect(find.text('1 khu vực · Bản đồ'), findsOneWidget);

      await tester.tap(find.text('Tầng G'));
      await tester.pumpAndSettle();

      expect(find.byType(FloorScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Tầng G'), findsOneWidget);
      // Khối khu vực trên bản đồ + nút ở dải dưới.
      expect(find.byKey(const ValueKey('block:gate')), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Đoan Môn'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('block:gate')));
      await tester.pumpAndSettle();
      expect(find.byType(AttractionMapScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Đoan Môn'), findsOneWidget);
    });

    testWidgets('tầng có sơ đồ nhưng chưa có khu vực thì báo rõ',
        (tester) async {
      await open(tester, 'hn');
      await tester.tap(find.text('Tầng 2'));
      await tester.pumpAndSettle();

      expect(find.byType(FloorScreen), findsOneWidget);
      expect(find.text('Tầng này chưa có khu vực nào.'), findsOneWidget);
    });

    testWidgets('địa điểm chưa có vị trí vẫn mở được qua nút danh sách',
        (tester) async {
      await openTab(tester);

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      expect(
        find.text('2 khu vực · 3 hiện vật · chưa có vị trí trên bản đồ'),
        findsOneWidget,
      );
      await tester.tap(find.text('Bảo tàng Huế'));
      await tester.pumpAndSettle();

      expect(find.byType(AreaAttractionsScreen), findsOneWidget);
      expect(find.text('Hội trường'), findsOneWidget);
      expect(find.text('Sân ngoài trời'), findsOneWidget);
    });

    testWidgets('đứng trong vùng beacon của địa điểm: ghim và dải "Bạn đang ở"',
        (tester) async {
      await openTab(tester);
      expect(find.text('Bạn đang ở Hoàng thành'), findsNothing);

      scan.startScan();
      scan.onBeaconSeen(
        ArtifactRepository.instance.tryById('a4')!,
        beacon: const BeaconCandidate(
          identity: BeaconIdentity(
              proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: 102),
          resolved: true,
          beaconId: 'b-gate',
          name: 'Beacon cổng',
          artifactIds: ['a4'],
        ),
      );
      await tester.pump();

      expect(find.text('Bạn đang ở Hoàng thành'), findsOneWidget);

      scan.stopScan();
      await tester.pump();
    });

    testWidgets('danh sách khu vực của một địa điểm', (tester) async {
      await open(tester);

      expect(find.widgetWithText(AppBar, 'Bảo tàng Huế'), findsOneWidget);
      expect(find.text('Chọn một khu vực để xem bản đồ'), findsOneWidget);
      expect(find.text('Hội trường'), findsOneWidget);
      expect(find.text('2 hiện vật · Bản đồ'), findsOneWidget);
      expect(find.text('Sân ngoài trời'), findsOneWidget);
      expect(find.text('1 hiện vật · Sơ đồ tầng'), findsOneWidget);
      // Khu du lịch khác không lẫn vào.
      expect(find.text('Đoan Môn'), findsNothing);
      expect(find.byType(AttractionMapScreen), findsNothing);
    });

    testWidgets('mỗi nút kèm mức đông của điểm; điểm không beacon thì không hiện',
        (tester) async {
      await open(tester);

      expect(find.text('~3 khách đang ở khu này'), findsOneWidget);
      // Sân ngoài trời không có beacon → không đo được, không được ghi "vắng".
      expect(find.text('Đang vắng khách'), findsNothing);
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

    testWidgets('bản đồ khu vực: "Xem tất cả" hiện khi đã kéo/zoom',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('Hội trường'));
      await tester.pumpAndSettle();
      final fitAll = find.byTooltip('Xem tất cả');
      expect(fitAll, findsNothing);

      await tester.tap(find.text('Hiện vật a1'));
      await tester.pumpAndSettle();
      dragMap(tester);
      await tester.pump();
      expect(fitAll, findsOneWidget);

      await tester.tap(fitAll);
      await tester.pumpAndSettle();
      expect(fitAll, findsNothing);
      expect(find.text('Chi tiết'), findsNothing);
      // Nút vị trí của tôi vẫn còn.
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('bấm khu trong nhà có sơ đồ tầng thì mở sơ đồ tầng',
        (tester) async {
      await open(tester);

      await tester.tap(find.text('Sân ngoài trời'));
      await tester.pumpAndSettle();

      expect(find.byType(FloorPlanScreen), findsOneWidget);
      expect(find.byType(AttractionMapScreen), findsNothing);
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
