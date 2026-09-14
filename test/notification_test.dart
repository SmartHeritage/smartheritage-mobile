import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen.dart';
import 'package:smartheritage/state/notification_state.dart';
import 'package:smartheritage/widgets/app_sidebar.dart';

/// Giống cách lồng ở MainShell: HomeScreen là body, không có Scaffold riêng.
Widget _harness() {
  return const MaterialApp(
    home: Scaffold(
      drawer: AppSidebar(),
      body: HomeScreen(),
    ),
  );
}

void main() {
  final store = NotificationController.instance;

  // Controller là singleton giữ trong bộ nhớ → về trạng thái gốc trước mỗi
  // test, không thì test sau thấy dữ liệu đã đọc của test trước.
  setUp(store.reset);

  testWidgets('badge hiện số thông báo chưa đọc', (tester) async {
    await tester.pumpWidget(_harness());

    expect(store.unreadCount, MockData.notifications.length);
    expect(find.text('${MockData.notifications.length}'), findsOneWidget);
  });

  testWidgets('bấm chuông mở màn hình thông báo', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Thông báo'), findsNothing);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Triển lãm chuyên đề cuối tuần'), findsOneWidget);
  });

  testWidgets('đánh dấu đã đọc xoá badge', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đánh dấu đã đọc'));
    await tester.pumpAndSettle();

    expect(store.unreadCount, 0);

    // Quay lại trang chủ: badge đã mất.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('${MockData.notifications.length}'), findsNothing);
  });

  testWidgets('bấm thông báo có hiện vật thì mở trang chi tiết',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    // n1 gắn artifactId 'a2' — Ấn vàng triều Nguyễn.
    await tester.tap(find.text('Bạn đang ở gần Ấn vàng triều Nguyễn'));
    await tester.pumpAndSettle();

    expect(find.text('Giới thiệu'), findsOneWidget);
    expect(store.isRead('n1'), isTrue);
  });

  testWidgets('thông báo không gắn hiện vật chỉ đánh dấu đã đọc',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Triển lãm chuyên đề cuối tuần'));
    await tester.pumpAndSettle();

    // Vẫn ở màn hình thông báo.
    expect(find.text('Thông báo'), findsOneWidget);
    expect(store.isRead('n3'), isTrue);
    expect(store.unreadCount, MockData.notifications.length - 1);
  });
}
