import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

/// Màn hình đứng dưới, dùng để kiểm tra khách thoát được khỏi trang đăng nhập
/// mà không cần đăng nhập.
class _Caller extends StatelessWidget {
  const _Caller();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => AuthController.ensureLoggedIn(context),
          child: const Text('MÀN TRƯỚC'),
        ),
      ),
    );
  }
}

void main() {
  final auth = AuthController.instance;

  setUp(auth.resetForTest);
  tearDown(auth.resetForTest);

  testWidgets('trang đăng nhập có nút back và thoát được', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const _Caller(),
    ));

    await tester.tap(find.text('MÀN TRƯỚC'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);

    // Nút back do AppBar sinh ra.
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại!'), findsNothing);
    expect(find.text('MÀN TRƯỚC'), findsOneWidget);
    expect(auth.isLoggedIn, isFalse);
  });
}
