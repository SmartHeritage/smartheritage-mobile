import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/favorite_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/services/api_client.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _apiArtifact(String id, String name) => {
      'id': id,
      'name': name,
      'era': 'Thời Lý',
      'zone': 'Khu trưng bày A',
      'shortIntro': 'Tóm tắt.',
      'description': 'Mô tả.',
      'rating': 4.5,
      'reviewCount': 2,
      'audioDuration': '03:00',
      'videoDuration': '02:00',
    };

Artifact _artifact(String id) =>
    Artifact.fromJson(_apiArtifact(id, 'Trống đồng Đông Sơn'));

FavoriteRepository _repo(MockClient mock) => FavoriteRepository(
      api: ApiClient(httpClient: mock, baseUrl: _base),
    );

void main() {
  test('mới mở app thì rỗng, chưa gọi gì', () {
    final repo = _repo(MockClient((_) async => _json([])));

    expect(repo.artifacts, isEmpty);
    expect(repo.ids, isEmpty);
    expect(repo.isFavorite('uuid-1'), isFalse);
  });

  test('load lấy danh sách từ GET /favorites', () async {
    final repo = _repo(MockClient((req) async {
      expect(req.method, 'GET');
      expect(req.url.path, '/api/v1/favorites');
      return _json([
        _apiArtifact('uuid-1', 'Trống đồng Đông Sơn'),
        _apiArtifact('uuid-2', 'Súng thần công'),
      ]);
    }));

    await repo.load();

    expect(repo.artifacts.map((a) => a.id), ['uuid-1', 'uuid-2']);
    expect(repo.isFavorite('uuid-1'), isTrue);
    expect(repo.isFavorite('uuid-3'), isFalse);
    expect(repo.isLoading, isFalse);
  });

  test('thêm yêu thích gọi PUT /favorites/:id', () async {
    final calls = <String>[];
    final repo = _repo(MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      return _json({'artifactId': 'uuid-1', 'favorite': true}, 201);
    }));

    final ok = await repo.toggle(_artifact('uuid-1'));

    expect(ok, isTrue);
    expect(calls, ['PUT /api/v1/favorites/uuid-1']);
    expect(repo.isFavorite('uuid-1'), isTrue);
    // Hiện vật vừa thích phải xuất hiện luôn trong danh sách, không cần load lại.
    expect(repo.artifacts.single.id, 'uuid-1');
  });

  test('bỏ yêu thích gọi DELETE và rút khỏi danh sách', () async {
    final calls = <String>[];
    final repo = _repo(MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.method == 'GET') {
        return _json([_apiArtifact('uuid-1', 'Trống đồng Đông Sơn')]);
      }
      return http.Response('', 204);
    }));
    await repo.load();

    final ok = await repo.toggle(_artifact('uuid-1'));

    expect(ok, isTrue);
    expect(calls.last, 'DELETE /api/v1/favorites/uuid-1');
    expect(repo.isFavorite('uuid-1'), isFalse);
    expect(repo.artifacts, isEmpty);
  });

  test('cập nhật giao diện ngay, không chờ mạng', () async {
    final gate = Completer<void>();
    final repo = _repo(MockClient((_) async {
      await gate.future;
      return _json({'favorite': true}, 201);
    }));

    final pending = repo.toggle(_artifact('uuid-1'));

    // Request còn đang treo mà trái tim đã đỏ.
    expect(repo.isFavorite('uuid-1'), isTrue);

    gate.complete();
    expect(await pending, isTrue);
  });

  test('request hỏng thì hoàn tác và báo thất bại', () async {
    final repo = _repo(MockClient(
        (_) async => _json({'message': 'Máy chủ lỗi'}, 500)));

    final ok = await repo.toggle(_artifact('uuid-1'));

    expect(ok, isFalse);
    // Điểm mấu chốt: không để trái tim đỏ trong khi server không hề lưu.
    expect(repo.isFavorite('uuid-1'), isFalse);
    expect(repo.artifacts, isEmpty);
  });

  test('mất mạng khi bỏ yêu thích thì trả lại hiện vật vào danh sách',
      () async {
    var loaded = false;
    final repo = _repo(MockClient((req) async {
      if (!loaded) {
        loaded = true;
        return _json([_apiArtifact('uuid-1', 'Trống đồng Đông Sơn')]);
      }
      throw const SocketException('mat mang');
    }));
    await repo.load();

    final ok = await repo.toggle(_artifact('uuid-1'));

    expect(ok, isFalse);
    expect(repo.isFavorite('uuid-1'), isTrue);
    expect(repo.artifacts.single.id, 'uuid-1');
  });

  test('load lỗi thì giữ nguyên danh sách đang có', () async {
    var first = true;
    final repo = _repo(MockClient((_) async {
      if (first) {
        first = false;
        return _json([_apiArtifact('uuid-1', 'Trống đồng Đông Sơn')]);
      }
      throw const SocketException('mat mang');
    }));
    await repo.load();

    await repo.load();

    expect(repo.isFavorite('uuid-1'), isTrue);
    expect(repo.isLoading, isFalse);
  });

  test('clear xoá sạch khi đăng xuất', () async {
    final repo = _repo(MockClient(
        (_) async => _json([_apiArtifact('uuid-1', 'Trống đồng Đông Sơn')])));
    await repo.load();
    expect(repo.artifacts, isNotEmpty);

    repo.clear();

    // Dữ liệu của người vừa đăng xuất không được ở lại cho người sau.
    expect(repo.artifacts, isEmpty);
    expect(repo.ids, isEmpty);
  });
}
