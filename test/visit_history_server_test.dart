import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/visit_history_state.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

/// Đúng shape một dòng của `GET /visits`.
Map<String, dynamic> _row(String artifactId, String name, String day) => {
      'id': 'visit-$artifactId-$day',
      'artifactId': artifactId,
      'artifactName': name,
      'imageUrl': null,
      'visitedOn': day,
      'lastScannedAt': '${day}T03:15:00.000Z',
      'scanCount': 2,
      'source': 'beacon',
    };

void main() {
  final history = VisitHistoryController.instance;
  final auth = AuthController.instance;
  late List<String> calls;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    history.apiForTest = ApiClient(
      baseUrl: _base,
      httpClient: MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        if (req.method == 'DELETE') return http.Response('', 204);
        return _json([
          _row('uuid-1', 'Trống đồng Đông Sơn', '2026-10-09'),
          _row('uuid-gone', 'Hiện vật đã gỡ', '2026-10-08'),
        ]);
      }),
    );
    ArtifactRepository.instance.setArtifactsForTest([
      Artifact.fromJson({
        'id': 'uuid-1',
        'name': 'Trống đồng Đông Sơn',
        'shortIntro': 'Bản đầy đủ trong danh mục.',
      }),
    ]);
    await history.load();
  });

  tearDownAll(() {
    auth.resetForTest();
    ArtifactRepository.instance.resetForTest();
  });

  test('khách thì dùng lịch sử trên máy, không gọi /visits', () {
    expect(history.isAccountHistory, isFalse);
    expect(calls, isEmpty);
  });

  test('đăng nhập thì chuyển sang GET /visits', () async {
    auth.setTestSession();
    await pumpEventQueue();

    expect(calls, contains('GET /api/v1/visits'));
    expect(history.isAccountHistory, isTrue);
    final records = history.records;
    expect(records.map((r) => r.artifact.name),
        ['Trống đồng Đông Sơn', 'Hiện vật đã gỡ']);
    // Có trong danh mục thì lấy bản đầy đủ; đã gỡ thì vẫn hiện tên backend gửi.
    expect(records.first.artifact.shortIntro, 'Bản đầy đủ trong danh mục.');
  });

  test('beacon phát hiện thì dòng mới lên đầu ngay, không chờ tải lại',
      () async {
    final artifact = ArtifactRepository.instance.tryById('uuid-1')!;
    await history.recordBeaconVisit(artifact);

    expect(history.records.first.dateLabel, 'Hôm nay');
    expect(history.records.first.artifact.id, 'uuid-1');
  });

  test('xoá lịch sử gọi DELETE /visits', () async {
    await history.clear();

    expect(calls, contains('DELETE /api/v1/visits'));
    expect(history.isEmpty, isTrue);
  });

  test('đăng xuất thì quay về lịch sử trên máy', () async {
    auth.resetForTest();
    await pumpEventQueue();

    expect(history.isAccountHistory, isFalse);
  });
}
