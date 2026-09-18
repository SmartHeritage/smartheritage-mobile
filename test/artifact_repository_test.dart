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

/// Một hiện vật đúng shape backend trả về, trùng tên với bản mock để kiểm tra
/// phần trình bày có được ghép vào không.
Map<String, dynamic> _apiArtifact({
  String id = 'uuid-1',
  String name = 'Trống đồng Đông Sơn',
  String zone = 'Khu trưng bày A',
}) =>
    {
      'id': id,
      'name': name,
      'era': 'Văn hoá Đông Sơn · TK VII TCN',
      'zone': zone,
      'zoneId': 'zone-uuid',
      'shortIntro': 'Biểu tượng rực rỡ của nền văn minh Việt cổ.',
      'description': 'Mô tả dài.',
      'rating': 4.8,
      'reviewCount': 4,
      'audioDuration': '03:45',
      'videoDuration': '02:10',
      'mapX': 0.26,
      'mapY': 0.3,
      'imageUrl': null,
      'audioUrl': null,
      'videoUrl': null,
    };

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

    test('hiện vật lạ vẫn dựng được, dùng icon và toạ độ mặc định', () {
      final artifact = Artifact.fromJson(
        _apiArtifact(id: 'uuid-x', name: 'Hiện vật chưa từng có'),
      );

      expect(artifact.name, 'Hiện vật chưa từng có');
      expect(artifact.imageAsset, isNull);
      expect(artifact.icon, Icons.museum_outlined);
      expect(artifact.lat, MockData.siteLat);
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
      expect(repo.zones.first, 'Tất cả');
      expect(repo.isOffline, isFalse);
    });

    test('tải xong thì thay bằng dữ liệu API và dựng bộ lọc từ /zones',
        () async {
      final repo = _repo(MockClient((req) async {
        if (req.url.path.endsWith('/zones')) {
          return _json([
            {'id': 'z1', 'name': 'Khu trưng bày A'},
            {'id': 'z2', 'name': 'Khu trưng bày B'},
          ]);
        }
        return _json([
          _apiArtifact(),
          _apiArtifact(
              id: 'uuid-2', name: 'Súng thần công', zone: 'Sân ngoài trời'),
        ]);
      }));

      await repo.refresh();

      expect(repo.artifacts.map((a) => a.id), ['uuid-1', 'uuid-2']);
      // 'Sân ngoài trời' không có trong bảng zones nhưng hiện vật vẫn thuộc về
      // nó — bộ lọc phải gộp thêm, không thì hiện vật đó không lọc ra được.
      expect(repo.zones, [
        'Tất cả',
        'Khu trưng bày A',
        'Khu trưng bày B',
        'Sân ngoài trời',
      ]);
      expect(repo.isOffline, isFalse);
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
        if (req.url.path.endsWith('/zones')) return _json([]);
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
        if (req.url.path.endsWith('/zones')) return _json([]);
        return _json([_apiArtifact()]);
      }));

      await repo.ensureLoaded();
      await repo.ensureLoaded();

      // 2 = một /artifacts + một /zones của lần tải duy nhất.
      expect(calls, 2);
    });
  });
}
