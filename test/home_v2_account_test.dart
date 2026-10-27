import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/about/about_screen.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/screens/profile/profile_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

Widget _harness() => MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreenV2()),
    );

void main() {
  final auth = AuthController.instance;

  setUp(auth.resetForTest);
  tearDown(auth.resetForTest);

  testWidgets('ô Cài đặt mở trang cá nhân cũ với tiêu đề Cài đặt',
      (tester) async {
    auth.setTestSession();
    await tester.pumpWidget(_harness());
    expect(find.text('Tài khoản'), findsNothing);

    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Cài đặt'), findsOneWidget);
    // Trang cá nhân cũ nhưng bỏ mục chỉnh sửa thông tin.
    expect(find.text('Chỉnh sửa thông tin cá nhân'), findsNothing);
    // Không còn thẻ thông tin tài khoản (tên, email) ở đầu trang.
    expect(find.text('lenhatanh2411@gmail.com'), findsNothing);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
  });

  testWidgets('mục Về ứng dụng ở trang Cài đặt mở trang Giới thiệu',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Về ứng dụng'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('khách bấm Cài đặt vẫn vào được, không bị bắt đăng nhập',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Chào mừng trở lại!'), findsNothing);
  });

  testWidgets('đã đăng nhập thì tiêu đề là lời chào kèm họ tên, đăng xuất thì về Trang chủ',
      (tester) async {
    await tester.pumpWidget(_harness());
    expect(find.text('Trang chủ'), findsOneWidget);

    auth.setTestSession(fullName: 'Lê Nhật Anh');
    await tester.pump();
    expect(find.text('Xin chào, Lê Nhật Anh'), findsOneWidget);
    expect(find.text('Trang chủ'), findsNothing);

    auth.resetForTest();
    await tester.pump();
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
