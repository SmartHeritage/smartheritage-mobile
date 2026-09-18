import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/token_store.dart';
import 'package:smartheritage/state/auth_state.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _user({String? fullName = 'Lê Nhật Anh'}) => {
      'id': 'u1',
      'email': 'lenhatanh2411@gmail.com',
      'fullName': fullName,
      'phone': null,
      'gender': null,
      'avatarUrl': null,
      'preferredLanguage': 'vi',
      'notificationsEnabled': true,
      'role': 'USER',
    };

AuthController _auth(MockClient mock) =>
    AuthController(api: ApiClient(httpClient: mock, baseUrl: _base));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStore.instance.clear();
  });

  test('mặc định là khách', () {
    final auth = _auth(MockClient((_) async => _json({})));

    expect(auth.isLoggedIn, isFalse);
    expect(auth.name, 'Khách');
    expect(auth.email, '');
  });

  test('đăng nhập thành công thì lưu token và dựng hồ sơ', () async {
    Map<String, dynamic>? sentBody;
    final auth = _auth(MockClient((req) async {
      sentBody = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({
        'accessToken': 'ACC',
        'refreshToken': 'REF',
        'user': _user(),
      });
    }));

    await auth.signIn(email: '  lenhatanh2411@gmail.com ', password: 'secret12');

    // Email được trim trước khi gửi.
    expect(sentBody?['email'], 'lenhatanh2411@gmail.com');
    expect(auth.isLoggedIn, isTrue);
    expect(auth.name, 'Lê Nhật Anh');
    expect(auth.email, 'lenhatanh2411@gmail.com');
    expect(TokenStore.instance.accessToken, 'ACC');
    expect(TokenStore.instance.refreshToken, 'REF');
  });

  test('sai mật khẩu thì ném ApiException và vẫn là khách', () async {
    final auth = _auth(MockClient(
        (_) async => _json({'message': 'Invalid email or password'}, 401)));

    await expectLater(
      auth.signIn(email: 'a@b.c', password: 'saipass1'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Invalid email or password')),
    );
    expect(auth.isLoggedIn, isFalse);
    expect(auth.isBusy, isFalse);
    expect(TokenStore.instance.hasSession, isFalse);
  });

  test('chưa đặt họ tên thì lấy phần trước @ của email', () async {
    final auth = _auth(MockClient((_) async => _json({
          'accessToken': 'ACC',
          'refreshToken': 'REF',
          'user': _user(fullName: null),
        })));

    await auth.signIn(email: 'lenhatanh2411@gmail.com', password: 'secret12');

    expect(auth.name, 'lenhatanh2411');
  });

  test('đăng ký thì gọi register rồi login, sau đó đặt họ tên', () async {
    final calls = <String>[];
    final auth = _auth(MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.url.path.endsWith('/auth/register')) {
        return _json(_user(fullName: null), 201);
      }
      if (req.url.path.endsWith('/auth/login')) {
        return _json({
          'accessToken': 'ACC',
          'refreshToken': 'REF',
          'user': _user(fullName: null),
        });
      }
      return _json(_user(fullName: 'Nguyễn Văn A'));
    }));

    await auth.signUp(
      email: 'moi@example.com',
      password: 'secret12',
      fullName: 'Nguyễn Văn A',
    );

    expect(calls, [
      'POST /api/v1/auth/register',
      'POST /api/v1/auth/login',
      'PATCH /api/v1/auth/me',
    ]);
    expect(auth.name, 'Nguyễn Văn A');
  });

  test('khôi phục phiên lúc mở app khi còn refresh token', () async {
    await TokenStore.instance.save(accessToken: 'ACC', refreshToken: 'REF');
    final auth = _auth(MockClient((req) async {
      expect(req.url.path, '/api/v1/auth/me');
      return _json(_user());
    }));

    await auth.restoreSession();

    expect(auth.isLoggedIn, isTrue);
    expect(auth.name, 'Lê Nhật Anh');
  });

  test('không có token lưu sẵn thì không gọi /auth/me', () async {
    var called = false;
    final auth = _auth(MockClient((_) async {
      called = true;
      return _json(_user());
    }));

    await auth.restoreSession();

    expect(called, isFalse);
    expect(auth.isLoggedIn, isFalse);
  });

  test('đăng xuất xoá phiên local ngay cả khi server lỗi', () async {
    final auth = _auth(MockClient((req) async {
      if (req.url.path.endsWith('/auth/logout')) {
        return _json({'message': 'boom'}, 500);
      }
      return _json({
        'accessToken': 'ACC',
        'refreshToken': 'REF',
        'user': _user(),
      });
    }));
    await auth.signIn(email: 'a@b.c', password: 'secret12');

    await auth.logout();

    expect(auth.isLoggedIn, isFalse);
    expect(TokenStore.instance.hasSession, isFalse);
  });

  test('refresh token chết thì tự về khách', () async {
    await TokenStore.instance.save(accessToken: 'OLD', refreshToken: 'DEAD');
    final auth = _auth(MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh')) {
        return _json({'message': 'Invalid refresh token'}, 401);
      }
      if (req.url.path.endsWith('/auth/me')) {
        // Lần đầu trả hồ sơ để vào trạng thái đã đăng nhập, lần sau 401.
        return TokenStore.instance.accessToken == 'OLD'
            ? _json(_user())
            : _json({'message': 'expired'}, 401);
      }
      return _json({'message': 'expired'}, 401);
    }));
    await auth.restoreSession();
    expect(auth.isLoggedIn, isTrue);

    // Một request bất kỳ sau khi access token hết hạn.
    await TokenStore.instance.save(accessToken: 'EXPIRED', refreshToken: 'DEAD');
    await expectLater(auth.updateProfile(fullName: 'X'),
        throwsA(isA<ApiException>()));

    expect(auth.isLoggedIn, isFalse);
  });
}
