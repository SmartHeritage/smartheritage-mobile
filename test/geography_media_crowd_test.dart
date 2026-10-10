import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/crowd_repository.dart';
import 'package:smartheritage/services/api_client.dart';

const _base = 'http://test.local/api/v1';
const _uuid = '11111111-2222-4333-8444-555555555555';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

ApiClient _api(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(httpClient: MockClient(handler), baseUrl: _base);

Map<String, dynamic> _artifact(String id, {List<String>? languages}) => {
      'id': id,
      'name': 'Hiện vật $id',
      'attractionId': 'attr-a',
      'latitude': 21.03,
      'longitude': 105.84,
      'language': ?(languages == null
          ? null
          : {
              'requested': 'vi',
              'source': 'request',
              'resolved': 'vi',
              'available': languages,
            }),
    };

void main() {
  group('ArtifactRepository — ngôn ngữ và địa lý', () {
    test('gửi ?language= và gộp language.available', () async {
      final queries = <String, String?>{};
      final repo = ArtifactRepository(api: _api((req) async {
        queries[req.url.path] = req.url.queryParameters['language'];
        if (req.url.path.endsWith('/attractions')) {
          return _json([
            {'id': 'attr-a', 'name': 'Điện Kính Thiên', 'mapType': 'INDOOR',
             'floorPlanUrl': 'https://cdn.example/plan.png'},
          ]);
        }
        if (req.url.path.endsWith('/tourism-areas')) {
          return _json([
            {'id': 'area-1', 'name': 'Hoàng thành', 'latitude': null,
             'longitude': null},
            {'id': 'area-2', 'name': 'Văn Miếu', 'latitude': 21.0277,
             'longitude': 105.8355},
          ]);
        }
        return _json([
          _artifact('uuid-1', languages: ['vi', 'en']),
          _artifact('uuid-2', languages: ['vi', 'fr']),
        ]);
      }))
        ..language = 'en';

      await repo.refresh();

      expect(queries['/api/v1/artifacts'], 'en');
      expect(repo.availableLanguages, unorderedEquals(['vi', 'en', 'fr']));
      // Khu chưa ghim toạ độ vẫn có trong danh sách, chỉ là không có điểm ghim.
      expect(repo.tourismAreas.map((a) => a.isPinned), [false, true]);
      expect(repo.tourismAreas.last.lat, 21.0277);
      expect(repo.attractions.single.hasFloorPlan, isTrue);
    });

    test('mã ngôn ngữ bị backend từ chối (400) thì tải theo mặc định',
        () async {
      final artifactQueries = <String?>[];
      final repo = ArtifactRepository(api: _api((req) async {
        if (!req.url.path.endsWith('/artifacts')) return _json([]);
        final lang = req.url.queryParameters['language'];
        artifactQueries.add(lang);
        if (lang != null) return _json({'message': 'Unknown language'}, 400);
        return _json([_artifact('uuid-1')]);
      }))
        ..language = 'xx';

      await repo.refresh();

      expect(artifactQueries, ['xx', null]);
      expect(repo.artifacts.single.id, 'uuid-1');
    });

    test('fetchAttractionMap đặt ghim theo mapX/mapY, bỏ thứ chưa đặt vị trí',
        () async {
      final repo = ArtifactRepository(api: _api((req) async {
        expect(req.url.path, '/api/v1/attractions/attr-a/map');
        return _json({
          'attraction': {
            'id': 'attr-a',
            'name': 'Điện Kính Thiên',
            'mapType': 'INDOOR',
            'floorPlanUrl': '/uploads/plans/a.png',
          },
          'beacons': [
            {'id': 'b1', 'name': 'Beacon tầng 1', 'mapX': 0.2, 'mapY': 0.4},
            {'id': 'b2', 'name': 'Beacon chưa đặt', 'mapX': null, 'mapY': null},
          ],
          'artifacts': [
            {..._artifact('uuid-1'), 'mapX': 0.5, 'mapY': 0.25},
          ],
        });
      }));
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final map = await repo.fetchAttractionMap('attr-a');

      expect(map.attraction.floorPlanUrl,
          'http://localhost:3000/uploads/plans/a.png');
      expect(map.markers.map((m) => m.name),
          ['Beacon tầng 1', 'Hiện vật uuid-1']);
      expect(map.markers.first.isBeacon, isTrue);
      expect(map.markers.last.artifact?.id, 'uuid-1');
      expect((map.markers.last.x, map.markers.last.y), (0.5, 0.25));
    });

    test('fetchImages chỉ lấy ảnh, bỏ audio/video', () async {
      final repo = ArtifactRepository(api: _api((req) async {
        expect(req.url.path, '/api/v1/artifacts/$_uuid/media');
        return _json([
          {'type': 'IMAGE', 'url': 'https://cdn.example/1.jpg',
           'caption': 'Mặt trống'},
          {'type': 'DETAIL_AUDIO', 'url': 'https://cdn.example/a.mp3'},
          {'type': 'GALLERY_IMAGE', 'url': 'https://cdn.example/2.jpg'},
          {'type': 'VIDEO', 'url': 'https://cdn.example/v.mp4'},
        ]);
      }));

      final images = await repo.fetchImages(_uuid);

      expect(images.map((i) => i.url),
          ['https://cdn.example/1.jpg', 'https://cdn.example/2.jpg']);
      expect(images.first.caption, 'Mặt trống');
    });

    test('hiện vật mock thì không gọi /media', () async {
      var called = false;
      final repo = ArtifactRepository(api: _api((_) async {
        called = true;
        return _json([]);
      }));

      expect(await repo.fetchImages('a1'), isEmpty);
      expect(called, isFalse);
    });
  });

  group('CrowdRepository', () {
    test('beacon một hiện vật → số của hiện vật; nhiều hiện vật → số cả khu',
        () async {
      final repo = CrowdRepository(api: _api((req) async {
        expect(req.url.path, '/api/v1/crowd/beacons');
        return _json([
          {
            'beaconId': 'b3',
            'beaconName': 'Beacon tầng 1',
            'activeDeviceCount': 4,
            'observationType': 'ARTIFACT',
            'artifactId': 'uuid-3',
            'artifactIds': ['uuid-3'],
            'ttlSeconds': 300,
          },
          {
            'beaconId': 'b1',
            'beaconName': 'Beacon sảnh chính',
            'activeDeviceCount': 9,
            'observationType': 'BEACON_ZONE',
            'artifactId': null,
            'artifactIds': ['uuid-1', 'uuid-2'],
            'ttlSeconds': 300,
          },
          {
            'beaconId': 'b5',
            'beaconName': 'Beacon sân',
            'activeDeviceCount': 0,
            'observationType': 'ARTIFACT',
            'artifactId': 'uuid-5',
            'artifactIds': ['uuid-5'],
            'ttlSeconds': 300,
          },
        ]);
      }));

      await repo.refresh();

      expect(repo.forArtifact('uuid-3')?.label, '~4 khách đang ở đây');
      expect(repo.forArtifact('uuid-1')?.label,
          '~9 khách quanh khu vực Beacon sảnh chính');
      expect(repo.forArtifact('uuid-2')?.isSharedZone, isTrue);
      expect(repo.forArtifact('uuid-5')?.label, 'Đang vắng khách');
      expect(repo.forArtifact('uuid-x'), isNull);
    });

    test('lỗi thì giữ số cũ', () async {
      var fail = false;
      final repo = CrowdRepository(api: _api((_) async {
        if (fail) return _json({'message': 'boom'}, 500);
        return _json([
          {
            'beaconName': 'B',
            'activeDeviceCount': 2,
            'observationType': 'ARTIFACT',
            'artifactId': 'uuid-1',
          },
        ]);
      }));
      await repo.refresh();
      fail = true;

      await repo.refresh();

      expect(repo.forArtifact('uuid-1')?.activeDevices, 2);
    });
  });
}
