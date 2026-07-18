import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/main.dart';

void main() {
  testWidgets('App khởi động và hiển thị màn hình splash', (tester) async {
    await tester.pumpWidget(const SmartHeritageApp());

    expect(find.text('Smart Heritage'), findsOneWidget);
    expect(find.text('Trợ lý du lịch số cho khu di tích'), findsOneWidget);

    // Chờ timer của splash hoàn tất để tránh pending timer.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
