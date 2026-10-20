import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/services/api_client.dart';

const _base = 'http://test.local/api/v1';

/// Backend trả JSON UTF-8. `http.Response(String, code)` mã hoá bằng latin1 nên
/// chữ tiếng Việt sẽ ném lỗi — phải dựng từ bytes như response thật.
http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

/// Một hiện vật đúng shape backend mới trả về (không còn `zone`; thuộc về một
/// Attraction qua `attractionId`), trùng tên với bản mock để kiểm tra phần
/// trình bày có được ghép vào không.
Map<String, dynamic> _apiArtifact({
  String id = 'uuid-1',
  String name = 'Trống đồng Đông Sơn',
  String? attractionId = 'attr-a',
  double? latitude,
  double? longitude,
}) =>
    {
      'id': id,
      'name': name,
      'era': 'Văn hoá Đông Sơn · TK VII TCN',
      'attractionId': attractionId,
      'status': 'PUBLISHED',
      'latitude': latitude,
      'longitude': longitude,
      'shortIntro': 'Biểu tượng rực rỡ của nền văn minh Việt cổ.',
      'description': 'Mô tả dài.',
      'rating': 4.8,
      'reviewCount': 4,
      'audioDuration': '03:45',
      'videoDuration': '02:10',
      'mapX': null,
      'mapY': null,
      'imageUrl': null,
      'audioUrl': null,
      'videoUrl': null,
    };

final _attractions = [
  {'id': 'attr-a', 'name': 'Điện Kính Thiên', 'tourismAreaId': 'area-1'},
  {'id': 'attr-b', 'name': 'Đoan Môn', 'tourismAreaId': 'area-1'},
  {'id': 'attr-empty', 'name': 'Hậu Lâu', 'tourismAreaId': 'area-1'},
];

ArtifactRepository _repo(MockClient mock) => ArtifactRepository(
      api: ApiClient(httpClient: mock, baseUrl: _base),
    );

void main() {
  group('Artifact.fromJson', () {
    test('lấy nội dung từ API và phần trình bày từ bản mock cùng tên', () {
      final artifact = Artifact.fromJson(_apiArtifact());

      // Nội dung: theo API, kể cả id UUID.
      expect(artifact.id, 'uuid-1');
      expect(artifact.name, 'Trống đồng Đông Sơn');
      expect(artifact.rating, 4.8);
      expect(artifact.reviewCount, 4);

      // Trình bày: theo mock, vì backend không có các trường này.
      final decor = MockData.artifacts.first;
      expect(artifact.imageAsset, decor.imageAsset);
      expect(artifact.icon, decor.icon);
      expect(artifact.lat, decor.lat);
      expect(artifact.lng, decor.lng);
    });

    test('ngôn ngữ khách chọn mà hiện vật chưa có thì ghi lại mã đó', () {
      Map<String, dynamic> withLanguage(String? resolved) => {
            ..._apiArtifact(),
            'language': {
              'requested': 'ja',
              'source': 'request',
              'resolved': resolved,
              'available': ['en', 'vi'],
            },
          };

      expect(Artifact.fromJson(withLanguage(null)).unavailableLanguage, 'ja');
      expect(Artifact.fromJson(withLanguage('ja')).unavailableLanguage, isNull);
      // Không gửi ngôn ngữ (không có khối language) thì không coi là thiếu.
      expect(Artifact.fromJson(_apiArtifact()).unavailableLanguage, isNull);
    });

    test('hiện vật lạ vẫn dựng được, dùng icon và toạ độ mặc định', () {
      final artifact = Artifact.fromJson(
        _apiArtifact(id: 'uuid-x', name: 'Hiện vật chưa từng có'),
      );

      expect(artifact.name, 'Hiện vật chưa từng có');
      expect(artifact.imageAsset, isNull);
      expect(artifact.icon, Icons.museum_outlined);
      expect(artifact.lat, MockData.siteLat);
    });

    test('toạ độ thật từ backend thắng toạ độ mock', () {
      final artifact = Artifact.fromJson(
        _apiArtifact(latitude: 21.04, longitude: 105.84),
      );

      expect(artifact.lat, 21.04);
      expect(artifact.lng, 105.84);
    });

    test('tên khu lấy từ attraction theo attractionId', () {
      final artifact = Artifact.fromJson(
        _apiArtifact(),
        attractionNames: const {'attr-a': 'Điện Kính Thiên'},
      );

      expect(artifact.zone, 'Điện Kính Thiên');
    });

    test('nhận rating dạng chuỗi (cột numeric của Postgres)', () {
      final json = _apiArtifact()..['rating'] = '4.3';
      expect(Artifact.fromJson(json).rating, 4.3);
    });

    test('imageUrl tương đối được ghép với origin của API', () {
      // flutter test chạy với defaultTargetPlatform = android, mà Android
      // emulator trỏ host qua 10.0.2.2 — ép về iOS để khẳng định nhánh
      // localhost, đồng thời ghi lại chính khác biệt đó.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final json = _apiArtifact()..['imageUrl'] = '/uploads/images/a.jpg';
      expect(
        Artifact.fromJson(json).imageUrl,
        'http://localhost:3000/uploads/images/a.jpg',
      );
    });

    test('Android emulator trỏ host qua 10.0.2.2', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final json = _apiArtifact()..['imageUrl'] = '/uploads/images/a.jpg';
      expect(
        Artifact.fromJson(json).imageUrl,
        'http://10.0.2.2:3000/uploads/images/a.jpg',
      );
    });

    test('URL tuyệt đối trỏ localhost thì đổi sang host của API', () {
      // /media và floorPlanUrl được backend ghép sẵn theo PUBLIC_BASE_URL.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        Artifact.resolveMediaUrl('http://localhost:3000/uploads/images/a.jpg'),
        'http://10.0.2.2:3000/uploads/images/a.jpg',
      );
    });

    test('imageUrl tuyệt đối thì giữ nguyên', () {
      final json = _apiArtifact()
        ..['imageUrl'] = 'https://upload.wikimedia.org/a.jpg';
      expect(
        Artifact.fromJson(json).imageUrl,
        'https://upload.wikimedia.org/a.jpg',
      );
    });
  });

  group('ArtifactRepository', () {
    test('trước khi tải thì đã có sẵn dữ liệu mock để vẽ', () {
      final repo = _repo(MockClient((_) async => http.Response('[]', 200)));

      expect(repo.artifacts, same(MockData.artifacts));
      expect(repo.attractions, isEmpty);
      expect(repo.isOffline, isFalse);
    });

    test('tải xong thì thay bằng dữ liệu API, tên khu lấy từ /attractions',
        () async {
      final paths = <String>[];
      final repo = _repo(MockClient((req) async {
        paths.add(req.url.path);
        if (req.url.path.endsWith('/attractions')) return _json(_attractions);
        return _json([
          _apiArtifact(),
          _apiArtifact(
              id: 'uuid-2', name: 'Súng thần công', attractionId: 'attr-b'),
        ]);
      }));

      await repo.refresh();

      expect(repo.artifacts.map((a) => a.id), ['uuid-1', 'uuid-2']);
      expect(repo.artifacts.map((a) => a.zone), ['Điện Kính Thiên', 'Đoan Môn']);
      expect(repo.attractions.map((a) => a.name),
          ['Điện Kính Thiên', 'Đoan Môn', 'Hậu Lâu']);
      // Backend mới không còn /zones — gọi tới là ăn 404.
      expect(paths.any((p) => p.endsWith('/zones')), isFalse);
      expect(repo.isOffline, isFalse);
    });

    test('/attractions hỏng thì vẫn hiện hiện vật thật', () async {
      final repo = _repo(MockClient((req) async {
        if (req.url.path.endsWith('/attractions')) {
          return _json({'message': 'boom'}, 500);
        }
        return _json([_apiArtifact()]);
      }));

      await repo.refresh();

      expect(repo.artifacts.map((a) => a.id), ['uuid-1']);
      expect(repo.artifacts.single.zone, isEmpty);
      expect(repo.attractions, isEmpty);
    });

    test('mất mạng thì giữ dữ liệu mock và bật cờ isOffline', () async {
      final repo = _repo(MockClient((_) async {
        throw const SocketException('connection refused');
      }));

      await repo.refresh();

      expect(repo.artifacts, same(MockData.artifacts));
      expect(repo.isOffline, isTrue);
    });

    test('lỗi 500 thì giữ dữ liệu cũ nhưng không coi là offline', () async {
      final repo = _repo(MockClient((_) async => _json({'message': 'boom'}, 500)));

      await repo.refresh();

      expect(repo.artifacts, same(MockData.artifacts));
      expect(repo.isOffline, isFalse);
    });

    test('tryById trả null cho id lạ, byId thì rơi về hiện vật đầu', () async {
      final repo = _repo(MockClient((req) async {
        if (req.url.path.endsWith('/attractions')) return _json([]);
        return _json([_apiArtifact()]);
      }));
      await repo.refresh();

      expect(repo.tryById('uuid-1')?.name, 'Trống đồng Đông Sơn');
      expect(repo.tryById('a1'), isNull);
      expect(repo.byId('a1').id, 'uuid-1');
    });

    test('ensureLoaded chỉ gọi mạng một lần', () async {
      var calls = 0;
      final repo = _repo(MockClient((req) async {
        calls++;
        if (req.url.path.endsWith('/attractions')) return _json([]);
        return _json([_apiArtifact()]);
      }));

      await repo.ensureLoaded();
      await repo.ensureLoaded();

      // 3 = /artifacts + /attractions + /tourism-areas của lần tải duy nhất.
      expect(calls, 3);
    });
  });
}
