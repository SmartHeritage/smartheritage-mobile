import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/app_info.dart';
import 'package:smartheritage/screens/help/help_screen.dart';
import 'package:smartheritage/screens/profile/profile_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

Widget _harness(Widget home) {
  return MaterialApp(theme: AppTheme.light, home: home);
}

void main() {
  setUp(() {
    AuthController.instance.resetForTest();
    // Clipboard đi qua platform channel; không mock thì setData không resolve
    // và snackbar phía sau nó không bao giờ hiện.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  testWidgets('hiện đủ 5 nhóm câu hỏi', (tester) async {
    await tester.pumpWidget(_harness(const HelpScreen()));

    expect(find.text('Trợ giúp & FAQ'), findsOneWidget);
    // ListView build lười nên phải cuộn tới từng nhóm, không assert cùng lúc.
    for (final title in [
      'iBeacon & phát hiện hiện vật',
      'Thuyết minh âm thanh',
      'Tài khoản',
      'Bản đồ & vị trí',
      'Thông báo & phản hồi',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget, reason: title);
    }
    final footer = find.text('Smart Heritage ${AppInfo.versionLabel}');
    await tester.scrollUntilVisible(footer, 200);
    expect(footer, findsOneWidget);
  });

  testWidgets('câu trả lời ẩn cho tới khi bấm vào câu hỏi', (tester) async {
    await tester.pumpWidget(_harness(const HelpScreen()));

    const question = 'iBeacon là gì và app dùng nó để làm gì?';
    expect(find.text(question), findsOneWidget);
    expect(find.textContaining('phát sóng Bluetooth'), findsNothing);

    await tester.tap(find.text(question));
    await tester.pumpAndSettle();

    expect(find.textContaining('phát sóng Bluetooth'), findsOneWidget);
  });

  testWidgets('mở được nhiều câu hỏi cùng lúc', (tester) async {
    await tester.pumpWidget(_harness(const HelpScreen()));

    await tester.tap(find.text('iBeacon là gì và app dùng nó để làm gì?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bật tính năng quét ở đâu?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('phát sóng Bluetooth'), findsOneWidget);
    expect(find.textContaining('công tắc "Quét iBeacon"'), findsWidgets);
  });

  testWidgets('bấm email thì sao chép vào clipboard', (tester) async {
    await tester.pumpWidget(_harness(const HelpScreen()));

    final email = find.text('hotro@smartheritage.vn');
    await tester.scrollUntilVisible(email, 300);
    // scrollUntilVisible chỉ đưa widget vào cây, nó còn nằm sát mép nên tap
    // trượt — ensureVisible mới kéo hẳn vào trong vùng nhìn thấy.
    await tester.ensureVisible(email);
    await tester.pumpAndSettle();
    await tester.tap(email);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Đã sao chép email hỗ trợ'), findsOneWidget);
  });

  testWidgets('vào được từ menu trang cá nhân', (tester) async {
    await tester.pumpWidget(_harness(const ProfileScreen()));

    final entry = find.text('Trợ giúp & câu hỏi thường gặp');
    await tester.scrollUntilVisible(entry, 300);
    // scrollUntilVisible dừng ngay khi widget tồn tại, có thể vẫn hụt vài px
    // dưới mép màn hình test — kéo hẳn vào trong rồi mới bấm.
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.text('Trợ giúp & FAQ'), findsOneWidget);
    expect(find.text('iBeacon & phát hiện hiện vật'), findsOneWidget);
  });
}
