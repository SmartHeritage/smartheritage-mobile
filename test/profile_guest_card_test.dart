import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/profile/profile_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

Widget _harness() {
  return MaterialApp(
    theme: AppTheme.light,
    home: const ProfileScreen(),
  );
}

void main() {
  final auth = AuthController.instance;

  setUp(auth.logout);
  tearDown(auth.logout);

  testWidgets('khách thấy card avatar với hai nút riêng', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Tham quan có tài khoản riêng'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsWidgets);

    // Hai nút tách biệt, không còn chip gộp "Đăng nhập / Đăng ký".
    expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Đăng ký'), findsOneWidget);
    expect(find.text('Đăng nhập / Đăng ký'), findsNothing);

    // Ba dòng lợi ích đã bỏ.
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text('Lưu hiện vật yêu thích'), findsNothing);
  });

  testWidgets('đã đăng nhập thì thay bằng card gradient', (tester) async {
    auth.login();
    await tester.pumpWidget(_harness());

    expect(find.text('Lê Nhật Anh'), findsOneWidget);
    expect(find.text('lenhatanh2411@gmail.com'), findsOneWidget);
    // Card guest biến mất hoàn toàn.
    expect(find.text('Tham quan có tài khoản riêng'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Đăng ký'), findsNothing);
  });

  testWidgets('nút đăng ký mở màn hình đăng ký', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    // RegisterScreen có ô nhập xác nhận điều khoản.
    expect(find.byType(Form), findsOneWidget);
    expect(find.text('Tham quan có tài khoản riêng'), findsNothing);
  });

  testWidgets('nút đăng nhập mở cổng đăng nhập', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.byType(Form), findsOneWidget);
    expect(find.text('Tham quan có tài khoản riêng'), findsNothing);
  });
}
