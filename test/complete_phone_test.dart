import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/data/favorite_repository.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/google_auth.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

class _NoopGoogleAuth extends GoogleAuth {
  @override
  Future<void> signOut() async {}
}

/// Màn gọi `ensureLoggedIn`, in kết quả ra để test đọc.
class _Caller extends StatefulWidget {
  const _Caller();

  @override
  State<_Caller> createState() => _CallerState();
}

class _CallerState extends State<_Caller> {
  bool? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final ok = await AuthController.ensureLoggedIn(context);
              setState(() => _result = ok);
            },
            child: const Text('MỞ'),
          ),
          Text('KẾT QUẢ: $_result'),
        ],
      ),
    );
  }
}

void main() {
  late AuthController original;
  late List<http.Request> requests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = AuthController.instance;
    GoogleAuth.instance = _NoopGoogleAuth();
    requests = [];
    final api = ApiClient(
      baseUrl: 'http://test.local/api/v1',
      httpClient: MockClient((req) async {
        requests.add(req);
        if (req.method == 'PATCH' && req.url.path.endsWith('/auth/me')) {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _json({
            'id': 'u1',
            'email': 'g@gmail.com',
            'googleUid': 'g-1',
            'phone': body['phone'],
          });
        }
        return _json({});
      }),
    );
    FavoriteRepository.instance = FavoriteRepository(api: api);
    AuthController.instance = AuthController(api: api);
  });

  tearDown(() {
    AuthController.instance.resetForTest();
    AuthController.instance = original;
    GoogleAuth.instance = GoogleAuth();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const _Caller()),
    );
    await tester.tap(find.text('MỞ'));
    await tester.pumpAndSettle();
  }

  test('chỉ tài khoản Google chưa có số mới phải nhập', () {
    expect(
      const AppUser(id: 'a', email: 'a', googleUid: 'g').needsPhone,
      isTrue,
    );
    expect(
      const AppUser(
        id: 'a',
        email: 'a',
        googleUid: 'g',
        phone: '  ',
      ).needsPhone,
      isTrue,
    );
    expect(
      const AppUser(
        id: 'a',
        email: 'a',
        googleUid: 'g',
        phone: '0901234567',
      ).needsPhone,
      isFalse,
    );
    expect(const AppUser(id: 'a', email: 'a').needsPhone, isFalse);
    expect(
      AppUser.fromJson({'id': 'a', 'email': 'a', 'googleUid': 'g'}).needsPhone,
      isTrue,
    );
  });

  testWidgets('nhập số hợp lệ thì PATCH /auth/me và cho đi tiếp', (
    tester,
  ) async {
    AuthController.instance.setTestSession(googleUid: 'g-1');
    await open(tester);
    expect(find.text('Thêm số điện thoại'), findsOneWidget);

    // Số quá ngắn bị chặn ngay, không gọi mạng.
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(find.byType(TextFormField), ' 0901234567 ');
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm số điện thoại'), findsNothing);
    expect(find.text('KẾT QUẢ: true'), findsOneWidget);
    expect(requests.single.method, 'PATCH');
    expect(jsonDecode(requests.single.body), {'phone': '0901234567'});
    expect(AuthController.instance.user?.phone, '0901234567');
  });

  testWidgets('bỏ ra thì đăng xuất', (tester) async {
    AuthController.instance.setTestSession(googleUid: 'g-1');
    await open(tester);

    await tester.tap(find.text('Dùng tài khoản khác'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm số điện thoại'), findsNothing);
    expect(find.text('KẾT QUẢ: false'), findsOneWidget);
    expect(AuthController.instance.isLoggedIn, isFalse);
  });

  testWidgets('nút back cũng là đăng xuất', (tester) async {
    AuthController.instance.setTestSession(googleUid: 'g-1');
    await open(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('KẾT QUẢ: false'), findsOneWidget);
    expect(AuthController.instance.isLoggedIn, isFalse);
  });

  testWidgets('tài khoản email hoặc đã có số thì không hỏi', (tester) async {
    AuthController.instance.setTestSession();
    await open(tester);
    expect(find.text('Thêm số điện thoại'), findsNothing);
    expect(find.text('KẾT QUẢ: true'), findsOneWidget);

    AuthController.instance.setTestSession(
      googleUid: 'g-1',
      phone: '0901234567',
    );
    await tester.tap(find.text('MỞ'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm số điện thoại'), findsNothing);
  });
}
