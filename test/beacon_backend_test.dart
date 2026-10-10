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
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Artifact _artifact(String id, String name, {String? audioUrl}) =>
    Artifact.fromJson({'id': id, 'name': name, 'audioUrl': audioUrl});

/// Đúng shape một phần tử `candidates` của `POST /beacons/resolve`.
Map<String, dynamic> _candidate(int minor, List<String> artifactIds) => {
      'resolved': true,
      'beaconId': 'beacon-$minor',
      'proximityUuid': AppConfig.demoProximityUuid,
      'major': AppConfig.demoMajor,
      'minor': minor,
      'name': 'Beacon $minor',
      'attractionId': null,
      'artifactIds': artifactIds,
      'artifacts': const [],
      'candidateCount': artifactIds.length,
      'singleCandidate': artifactIds.length == 1,
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('BeaconRepository', () {
    test('resolve gửi mọi beacon nghe được và đọc candidates', () async {
      late Map<String, dynamic> sent;
      final repo = BeaconRepository(
        api: ApiClient(
          baseUrl: _base,
          httpClient: MockClient((req) async {
            expect(req.url.path, '/api/v1/beacons/resolve');
            sent = jsonDecode(req.body) as Map<String, dynamic>;
            return _json({
              'candidates': [
                _candidate(101, ['uuid-1', 'uuid-2']),
                {
                  'resolved': false,
                  'proximityUuid': AppConfig.demoProximityUuid,
                  'major': 1,
                  'minor': 999,
                  'artifactIds': const [],
                },
              ],
            });
          }),
        ),
      );

      final result = await repo.resolve(const [
        BeaconIdentity(
            proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: 101),
        BeaconIdentity(
            proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: 999),
      ]);

      expect((sent['beacons'] as List).length, 2);
      expect(result.first.resolved, isTrue);
      expect(result.first.artifactIds, ['uuid-1', 'uuid-2']);
      expect(result.last.resolved, isFalse);
    });

    test('recordScan gửi deviceId ổn định, artifactId và source', () async {
      final bodies = <Map<String, dynamic>>[];
      final repo = BeaconRepository(
        api: ApiClient(
          baseUrl: _base,
          httpClient: MockClient((req) async {
            expect(req.url.path, '/api/v1/scans');
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return _json({'created': true}, 201);
          }),
        ),
      );
      const beacon = BeaconIdentity(
          proximityUuid: AppConfig.demoProximityUuid, major: 1, minor: 101);

      await repo.recordScan(beacon, artifactId: 'uuid-1', source: 'manual');
      await repo.recordScan(beacon);

      expect(bodies.first['minor'], 101);
      expect(bodies.first['artifactId'], 'uuid-1');
      expect(bodies.first['source'], 'manual');
      expect(bodies.last.containsKey('artifactId'), isFalse);
      // Cùng một máy → cùng một deviceId, đúng định dạng backend nhận.
      expect(bodies.first['deviceId'], bodies.last['deviceId']);
      expect(bodies.first['deviceId'],
          matches(RegExp(r'^[A-Za-z0-9-]{8,64}$')));
    });
  });

  group('BeaconScanController với backend', () {
    final scan = BeaconScanController.instance;
    final catalog = [
      _artifact('uuid-1', 'Trống đồng Đông Sơn'),
      _artifact('uuid-2', 'Ấn vàng triều Nguyễn',
          audioUrl: 'https://cdn.example/an-vang.mp3'),
      _artifact('uuid-3', 'Tượng Phật A Di Đà'),
    ];
    late List<String> calls;
    late List<Map<String, dynamic>> scans;
    late DateTime now;

    setUp(() {
      calls = [];
      scans = [];
      now = DateTime(2026, 10, 9, 10);
      scan.stopScan();
      scan.clockForTest = () => now;
      ArtifactRepository.instance.setArtifactsForTest(catalog);
      BeaconRepository.instance = BeaconRepository(
        api: ApiClient(
          baseUrl: _base,
          httpClient: MockClient((req) async {
            calls.add(req.url.path);
            if (req.url.path.endsWith('/beacons/resolve')) {
              return _json({
                'candidates': [
                  _candidate(101, ['uuid-1', 'uuid-2']),
                  _candidate(103, ['uuid-3']),
                ],
              });
            }
            scans.add(jsonDecode(req.body) as Map<String, dynamic>);
            return _json({'created': true}, 201);
          }),
        ),
      );
    });

    tearDown(() {
      scan.stopScan();
      scan.resetClockForTest();
      ArtifactRepository.instance.resetForTest();
    });

    testWidgets('hiện vật phát hiện lấy từ /beacons/resolve và ghi /scans',
        (tester) async {
      await tester.pumpWidget(const SizedBox());
      scan.startScan();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Beacon 101 phục vụ hai hiện vật: app chọn cái có thuyết minh, rồi báo
      // backend đúng hiện vật đã chọn để lượt ghé không bị tính nhầm.
      expect(scan.detected?.id, 'uuid-2');
      expect(scans, hasLength(1));
      expect(scans.single['minor'], 101);
      expect(scans.single['artifactId'], 'uuid-2');
      expect(scans.single['source'], 'manual');
      scan.stopScan();
    });

    testWidgets('chỉ resolve một lần mỗi phiên, /scans giãn theo 60 giây',
        (tester) async {
      await tester.pumpWidget(const SizedBox());
      scan.startScan();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Đứng yên 30 giây: hơn chục nhịp ranging nhưng không thêm request nào.
      for (var i = 0; i < 15; i++) {
        now = now.add(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
      }
      expect(calls.where((p) => p.endsWith('/beacons/resolve')), hasLength(1));
      expect(scans, hasLength(1));

      // Qua mốc 60 giây vẫn còn đứng đó → báo thêm một lượt để giữ "có mặt".
      for (var i = 0; i < 16; i++) {
        now = now.add(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
      }
      expect(scans, hasLength(2));
      scan.stopScan();
    });

    testWidgets('backend không nhận ra beacon nào thì rơi về danh mục',
        (tester) async {
      BeaconRepository.instance = BeaconRepository(
        api: ApiClient(
          baseUrl: _base,
          httpClient: MockClient((req) async {
            calls.add(req.url.path);
            return _json({'candidates': const []});
          }),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      scan.startScan();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(scan.detected?.id, 'uuid-2');
      // Không biết beacon nào thì không có gì để ghi /scans.
      expect(calls.where((p) => p.endsWith('/scans')), isEmpty);
      scan.stopScan();
    });
  });
}
