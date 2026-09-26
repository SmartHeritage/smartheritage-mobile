import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/profile/profile_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

/// Trang chủ giả: ở bản V2 trang Tài khoản được push chồng lên trang chủ,
/// nên sau khi đăng xuất phải quay về được màn hình phía dưới.
class _FakeHome extends StatelessWidget {
  const _FakeHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: const Text('TRANG CHỦ'),
        ),
      ),
    );
  }
}

void main() {
  final auth = AuthController.instance;

  setUp(auth.resetForTest);
  tearDown(auth.resetForTest);

  testWidgets('đăng xuất xong thì quay về trang chủ', (tester) async {
    auth.setTestSession();
    // Màn hình Tài khoản dài hơn khung test mặc định (800x600); nới cao lên
    // để nút Đăng xuất được dựng, khỏi phải cuộn.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const _FakeHome(),
    ));

    // Mở trang Tài khoản như lưới tính năng của V2 vẫn làm.
    await tester.tap(find.text('TRANG CHỦ'));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản của tôi'), findsOneWidget);

    // Đăng xuất + xác nhận trong hộp thoại.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản của tôi'), findsNothing,
        reason: 'trang Tài khoản phải bị đóng');
    expect(find.text('TRANG CHỦ'), findsOneWidget,
        reason: 'phải về lại trang chủ');
    expect(auth.isLoggedIn, isFalse);
  });

  testWidgets('bấm Huỷ thì ở nguyên trang Tài khoản', (tester) async {
    auth.setTestSession();
    // Màn hình Tài khoản dài hơn khung test mặc định (800x600); nới cao lên
    // để nút Đăng xuất được dựng, khỏi phải cuộn.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const _FakeHome(),
    ));
    await tester.tap(find.text('TRANG CHỦ'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Huỷ'));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản của tôi'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
  });
}
