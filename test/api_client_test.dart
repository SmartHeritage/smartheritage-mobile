import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/token_store.dart';

const _base = 'http://test.local/api/v1';

ApiClient _client(MockClient mock) =>
    ApiClient(httpClient: mock, baseUrl: _base);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStore.instance.clear();
  });

  test('gắn bearer token vào request khi đã có phiên', () async {
    String? seenAuth;
    final api = _client(MockClient((req) async {
      seenAuth = req.headers['authorization'];
      return http.Response('[]', 200);
    }));
    await TokenStore.instance.save(accessToken: 'AAA', refreshToken: 'RRR');

    await api.get('/artifacts');

    expect(seenAuth, 'Bearer AAA');
  });

  test('không có phiên thì không gắn header authorization', () async {
    var hasAuth = true;
    final api = _client(MockClient((req) async {
      hasAuth = req.headers.containsKey('authorization');
      return http.Response('[]', 200);
    }));

    await api.get('/artifacts');

    expect(hasAuth, isFalse);
  });

  test('lỗi 4xx lấy đúng message của backend', () async {
    final api = _client(MockClient((req) async => http.Response(
          jsonEncode({'status': 401, 'message': 'Invalid email or password'}),
          401,
        )));

    await expectLater(
      api.post('/auth/login', body: {'email': 'a@b.c', 'password': 'x'}),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Invalid email or password')
          .having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('server trả HTML (sai baseUrl) vẫn ra ApiException, không lỗi parse',
      () async {
    final api = _client(MockClient(
        (req) async => http.Response('<html>Cannot GET /artifacts</html>', 404)));

    await expectLater(
      api.get('/artifacts'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 404)
          .having((e) => e.isNetwork, 'isNetwork', isFalse)),
    );
  });

  test('không gọi tới được server thì đánh dấu isNetwork', () async {
    final api = _client(MockClient((req) async {
      throw const SocketException('connection refused');
    }));

    await expectLater(
      api.get('/artifacts'),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', isTrue)),
    );
  });

  test('401 thì tự refresh rồi gửi lại request đúng một lần', () async {
    final calls = <String>[];
    final api = _client(MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.url.path.endsWith('/auth/refresh')) {
        return http.Response(
          jsonEncode({'accessToken': 'NEW', 'refreshToken': 'NEW_R'}),
          200,
        );
      }
      // Token cũ bị từ chối, token mới thì chấp nhận.
      if (req.headers['authorization'] == 'Bearer NEW') {
        return http.Response(jsonEncode({'email': 'a@b.c'}), 200);
      }
      return http.Response(jsonEncode({'message': 'expired'}), 401);
    }));
    await TokenStore.instance.save(accessToken: 'OLD', refreshToken: 'RRR');

    final result = await api.get('/auth/me');

    expect(result, {'email': 'a@b.c'});
    expect(calls, [
      'GET /api/v1/auth/me',
      'POST /api/v1/auth/refresh',
      'GET /api/v1/auth/me',
    ]);
    expect(TokenStore.instance.accessToken, 'NEW');
    expect(TokenStore.instance.refreshToken, 'NEW_R');
  });

  test('refresh cũng hỏng thì xoá phiên và báo hết hạn', () async {
    var expired = false;
    final api = _client(MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh')) {
        return http.Response(jsonEncode({'message': 'Invalid refresh token'}), 401);
      }
      return http.Response(jsonEncode({'message': 'expired'}), 401);
    }))
      ..onSessionExpired = () => expired = true;
    await TokenStore.instance.save(accessToken: 'OLD', refreshToken: 'DEAD');

    await expectLater(api.get('/auth/me'), throwsA(isA<ApiException>()));

    expect(expired, isTrue);
    expect(TokenStore.instance.hasSession, isFalse);
  });

  test('204 No Content trả về null thay vì lỗi parse', () async {
    final api = _client(MockClient((req) async => http.Response('', 204)));

    expect(await api.post('/auth/logout', body: {'refreshToken': 'x'}), isNull);
  });
}
