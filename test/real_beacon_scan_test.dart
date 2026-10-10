import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/config.dart';
import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/beacon_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/ibeacon_scanner.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

BeaconIdentity _id(int minor) => BeaconIdentity(
    proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: minor);

HeardBeacon _heard(int minor, double meters) =>
    HeardBeacon(identity: _id(minor), distanceMeters: meters, rssi: -60);

/// Bluetooth giả: test tự đẩy từng nhịp quét qua [emit].
class _FakeSource implements BeaconSource {
  _FakeSource({this.error});

  final String? error;
  void Function(List<HeardBeacon>)? _onHeard;
  bool stopped = false;

  @override
  Future<String?> start(void Function(List<HeardBeacon>) onHeard) async {
    if (error != null) return error;
    _onHeard = onHeard;
    return null;
  }

  @override
  Future<void> stop() async => stopped = true;

  void emit(List<HeardBeacon> heard) => _onHeard?.call(heard);
}

void main() {
  final scan = BeaconScanController.instance;
  late _FakeSource source;
  late List<List<int>> resolveCalls;
  late List<Map<String, dynamic>> scans;
  late bool backendDown;
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resolveCalls = [];
    scans = [];
    backendDown = false;
    now = DateTime(2026, 10, 9, 10);
    scan.stopScan();
    scan.clockForTest = () => now;
    source = _FakeSource();
    scan.sourceForTest = source;
    ArtifactRepository.instance.setArtifactsForTest([
      Artifact.fromJson({'id': 'uuid-1', 'name': 'Trống đồng Đông Sơn'}),
      Artifact.fromJson({
        'id': 'uuid-2',
        'name': 'Ấn vàng triều Nguyễn',
        'audioUrl': 'https://cdn.example/an-vang.mp3',
      }),
      Artifact.fromJson({'id': 'uuid-3', 'name': 'Tượng Phật A Di Đà'}),
    ]);
    // 101 phục vụ hai hiện vật, 103 một hiện vật, 999 backend không biết.
    BeaconRepository.instance = BeaconRepository(
      api: ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          if (backendDown) throw http.ClientException('down');
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          if (req.url.path.endsWith('/scans')) {
            scans.add(body);
            return _json({'created': true}, 201);
          }
          final asked = [
            for (final b in body['beacons'] as List) (b as Map)['minor'] as int,
          ];
          resolveCalls.add(asked);
          return _json({
            'candidates': [
              for (final minor in asked)
                {
                  'resolved': minor != 999,
                  'beaconId': minor == 999 ? null : 'b-$minor',
                  'proximityUuid': AppConfig.demoProximityUuid,
                  'major': 1,
                  'minor': minor,
                  'name': minor == 999 ? null : 'Beacon $minor',
                  'artifactIds': switch (minor) {
                    101 => ['uuid-1', 'uuid-2'],
                    103 => ['uuid-3'],
                    _ => <String>[],
                  },
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
    scan.resetClockForTest();
    ArtifactRepository.instance.resetForTest();
  });

  test('chọn beacon gần nhất, ghi /scans với source beacon', () async {
    expect(await scan.startScan(), isNull);
    expect(scan.isScanning, isTrue);

    source.emit([_heard(103, 3.5), _heard(101, 1.2)]);
    await pumpEventQueue();

    // 101 gần hơn; trong hai hiện vật của nó, ưu tiên cái có thuyết minh.
    expect(scan.detected?.id, 'uuid-2');
    expect(scan.currentZone?.name, 'Beacon 101');
    expect(scans.single['minor'], 101);
    expect(scans.single['artifactId'], 'uuid-2');
    expect(scans.single['source'], 'beacon');
  });

  test('beacon ở xa hơn ngưỡng hoặc không ước lượng được thì bỏ qua', () async {
    await scan.startScan();

    source.emit([
      _heard(101, AppConfig.beaconMaxMeters + 1),
      _heard(103, -1),
    ]);
    await pumpEventQueue();

    expect(scan.detected, isNull);
    expect(resolveCalls, isEmpty);
  });

  test('mỗi beacon chỉ hỏi backend một lần, kể cả beacon lạ', () async {
    await scan.startScan();

    for (var i = 0; i < 5; i++) {
      source.emit([_heard(999, 0.5), _heard(103, 2)]);
      await pumpEventQueue();
    }

    expect(resolveCalls, [
      [999, 103],
    ]);
    // Beacon lạ ở gần nhất nhưng backend không biết → lấy beacon kế tiếp.
    expect(scan.detected?.id, 'uuid-3');
  });

  test('mất mạng thì nghỉ 15 giây mới hỏi lại', () async {
    await scan.startScan();
    backendDown = true;

    source.emit([_heard(103, 1)]);
    await pumpEventQueue();
    source.emit([_heard(103, 1)]);
    await pumpEventQueue();
    expect(scan.detected, isNull);

    backendDown = false;
    now = now.add(const Duration(seconds: 16));
    source.emit([_heard(103, 1)]);
    await pumpEventQueue();

    expect(resolveCalls, [
      [103],
    ]);
    expect(scan.detected?.id, 'uuid-3');
  });

  test('bật không được (Bluetooth tắt) thì báo lỗi và không quét', () async {
    scan.sourceForTest = _FakeSource(error: 'Hãy bật Bluetooth để quét beacon.');

    final error = await scan.startScan();

    expect(error, 'Hãy bật Bluetooth để quét beacon.');
    expect(scan.isScanning, isFalse);
    expect(scan.startError, error);
  });

  test('tắt quét thì dừng Bluetooth và quên kết quả resolve', () async {
    await scan.startScan();
    source.emit([_heard(103, 1)]);
    await pumpEventQueue();

    scan.stopScan();
    expect(source.stopped, isTrue);

    await scan.startScan();
    source.emit([_heard(103, 1)]);
    await pumpEventQueue();
    // Phiên mới hỏi lại backend — admin có thể vừa gán lại beacon.
    expect(resolveCalls, hasLength(2));
  });
}
