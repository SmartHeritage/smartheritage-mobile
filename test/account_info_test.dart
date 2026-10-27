import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/auth/login_screen.dart';
import 'package:smartheritage/screens/profile/account_info_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

Widget _harness() => MaterialApp(
      theme: AppTheme.light,
      home: const AccountInfoScreen(),
    );

void main() {
  final auth = AuthController.instance;

  setUp(auth.resetForTest);
  tearDown(auth.resetForTest);

  testWidgets('hiện họ tên, email; trường chưa có thì ghi Chưa cập nhật',
      (tester) async {
    auth.setTestSession(fullName: 'Lê Nhật Anh', email: 'a@example.com');
    await tester.pumpWidget(_harness());

    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Lê Nhật Anh'), findsOneWidget);
    expect(find.text('a@example.com'), findsOneWidget);
    // Phiên test không có số điện thoại.
    expect(find.text('Chưa cập nhật'), findsOneWidget);
    // Giới tính đã bỏ khỏi trang này.
    expect(find.text('Giới tính'), findsNothing);
    expect(find.widgetWithText(AppBar, 'Thông tin tài khoản'), findsOneWidget);
  });

  testWidgets('chỉ xem: không có ô nhập, không có nút lưu', (tester) async {
    auth.setTestSession();
    await tester.pumpWidget(_harness());

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Lưu thay đổi'), findsNothing);
  });

  testWidgets('khách thấy lời mời đăng nhập', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Đăng nhập để xem thông tin tài khoản'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập / Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('đăng nhập xong thì hiện thông tin ngay', (tester) async {
    await tester.pumpWidget(_harness());
    auth.setTestSession(fullName: 'Lê Nhật Anh');
    await tester.pump();
    expect(find.text('Lê Nhật Anh'), findsOneWidget);
  });
}
