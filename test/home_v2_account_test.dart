import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/home/home_screen_v2.dart';
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

  testWidgets('khách bấm Tài khoản thì vào thẳng trang đăng nhập',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    expect(find.text('Tài khoản của tôi'), findsNothing);
  });

  testWidgets('bấm back ở trang đăng nhập thì không mở trang cá nhân',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại!'), findsNothing);
    expect(find.text('Tài khoản của tôi'), findsNothing);
    expect(find.text('Trang chủ'), findsOneWidget);
  });

  testWidgets('đã đăng nhập thì bấm Tài khoản vào thẳng trang cá nhân',
      (tester) async {
    auth.setTestSession();
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản của tôi'), findsOneWidget);
    expect(find.text('Chào mừng trở lại!'), findsNothing);
  });
}
