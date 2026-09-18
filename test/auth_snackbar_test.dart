import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/screens/auth/login_screen.dart';
import 'package:smartheritage/screens/profile/profile_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/token_store.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';
import 'package:smartheritage/widgets/app_sidebar.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _session() => {
      'accessToken': 'ACC',
      'refreshToken': 'REF',
      'user': {
        'id': 'u1',
        'email': 'lenhatanh2411@gmail.com',
        'fullName': 'Lê Nhật Anh',
        'preferredLanguage': 'vi',
        'notificationsEnabled': true,
      },
    };

/// Cài controller chạy trên ApiClient giả vào chỗ singleton, để màn hình thật
/// đi qua đúng luồng đăng nhập mà không cần backend.
void _installAuth(MockClient mock) {
  AuthController.instance =
      AuthController(api: ApiClient(httpClient: mock, baseUrl: _base));
}

Widget _harness(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: child,
    );

/// Màu nền thực tế của snackbar đang hiện: `null` nghĩa là lấy theo theme.
Color? _snackBarColor(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor;

Future<void> _fillLoginForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'lenhatanh2411@gmail.com');
  await tester.enterText(fields.at(1), 'secret12');
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStore.instance.clear();
  });

  tearDown(() {
    AuthController.instance = AuthController();
  });

  testWidgets('đăng nhập thành công thì hiện snackbar', (tester) async {
    _installAuth(MockClient((_) async => _json(_session())));
    await tester.pumpWidget(_harness(const LoginScreen()));

    await _fillLoginForm(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập thành công'), findsOneWidget);
    expect(AuthController.instance.isLoggedIn, isTrue);
    // Không tự đặt màu → lấy nền xanh mặc định của theme.
    expect(_snackBarColor(tester), isNull);
    expect(AppTheme.light.snackBarTheme.backgroundColor, AppColors.success);
  });

  testWidgets('snackbar vẫn sống sau khi màn đăng nhập bị pop', (tester) async {
    _installAuth(MockClient((_) async => _json(_session())));
    // Mô phỏng "cổng đăng nhập": LoginScreen được push lên trên một màn khác,
    // đăng nhập xong sẽ pop — snackbar phải hiện ở màn phía dưới.
    await tester.pumpWidget(_harness(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('mở cổng đăng nhập'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('mở cổng đăng nhập'));
    await tester.pumpAndSettle();
    await _fillLoginForm(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // Đã quay về màn gốc…
    expect(find.text('mở cổng đăng nhập'), findsOneWidget);
    // …và snackbar không bị nuốt theo route vừa pop.
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });

  testWidgets('sai mật khẩu thì hiện lỗi của server, không hiện snackbar thành công',
      (tester) async {
    _installAuth(MockClient(
        (_) async => _json({'message': 'Invalid email or password'}, 401)));
    await tester.pumpWidget(_harness(const LoginScreen()));

    await _fillLoginForm(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.text('Đăng nhập thành công'), findsNothing);
    expect(AuthController.instance.isLoggedIn, isFalse);
    // Lỗi phải đỏ, không được xanh như thông báo thành công.
    expect(_snackBarColor(tester), AppColors.danger);
  });

  testWidgets('nút Google báo chưa hỗ trợ bằng snackbar đỏ', (tester) async {
    _installAuth(MockClient((_) async => _json(_session())));
    await tester.pumpWidget(_harness(const LoginScreen()));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Tiếp tục với Google'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập Google chưa được hỗ trợ'), findsOneWidget);
    expect(_snackBarColor(tester), AppColors.danger);
    expect(AuthController.instance.isLoggedIn, isFalse);
  });

  testWidgets('đăng xuất ở trang cá nhân thì hiện snackbar', (tester) async {
    _installAuth(MockClient((_) async => http.Response('', 204)));
    AuthController.instance.setTestSession();
    await tester.pumpWidget(_harness(const ProfileScreen()));

    final logout = find.widgetWithText(OutlinedButton, 'Đăng xuất');
    await tester.scrollUntilVisible(logout, 200);
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    // Xác nhận trong dialog.
    await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đã đăng xuất'), findsOneWidget);
    expect(_snackBarColor(tester), isNull);
    expect(AuthController.instance.isLoggedIn, isFalse);
  });

  testWidgets('đăng xuất ở sidebar thì hiện snackbar', (tester) async {
    _installAuth(MockClient((_) async => http.Response('', 204)));
    AuthController.instance.setTestSession();
    await tester.pumpWidget(_harness(
      const Scaffold(drawer: AppSidebar(), body: SizedBox.shrink()),
    ));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đã đăng xuất'), findsOneWidget);
    expect(AuthController.instance.isLoggedIn, isFalse);
  });
}
