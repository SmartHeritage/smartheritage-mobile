import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen.dart';
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

Future<void> _search(WidgetTester tester, String q) async {
  await tester.enterText(find.byType(TextField), q);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('không có nút filter ở ô search', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget);
    // Nút xoá chỉ hiện khi đã gõ.
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('lọc theo tên hiện vật', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Hiện vật nổi bật'), findsOneWidget);

    await _search(tester, 'trống đồng');

    expect(find.text('Kết quả tìm kiếm (1)'), findsOneWidget);
    expect(find.text('Hiện vật nổi bật'), findsNothing);
    expect(find.text('Trống đồng Đông Sơn'), findsOneWidget);
    expect(find.text('Ấn vàng triều Nguyễn'), findsNothing);
  });

  testWidgets('lọc theo khu trưng bày và thời kỳ', (tester) async {
    await tester.pumpWidget(_harness());

    await _search(tester, 'Khu trưng bày B');
    expect(find.text('Ấn vàng triều Nguyễn'), findsOneWidget);
    expect(find.text('Trống đồng Đông Sơn'), findsNothing);

    await _search(tester, 'Đông Sơn');
    // Khớp cả tên và thời kỳ của cùng một hiện vật → vẫn 1 kết quả.
    expect(find.text('Kết quả tìm kiếm (1)'), findsOneWidget);
    expect(find.text('Trống đồng Đông Sơn'), findsOneWidget);
  });

  testWidgets('không phân biệt hoa thường', (tester) async {
    await tester.pumpWidget(_harness());

    await _search(tester, 'TRỐNG ĐỒNG');
    expect(find.text('Trống đồng Đông Sơn'), findsOneWidget);
  });

  testWidgets('không có kết quả thì hiện empty state', (tester) async {
    await tester.pumpWidget(_harness());

    await _search(tester, 'xyz không tồn tại');

    expect(find.text('Kết quả tìm kiếm (0)'), findsOneWidget);
    expect(find.text('Không tìm thấy hiện vật'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('nút xoá trả về danh sách đầy đủ', (tester) async {
    await tester.pumpWidget(_harness());

    await _search(tester, 'trống đồng');
    expect(find.text('Kết quả tìm kiếm (1)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Hiện vật nổi bật'), findsOneWidget);
    expect(find.text('Kết quả tìm kiếm (1)'), findsNothing);

    // Danh sách đầy đủ trở lại. ListView build lười nên phải cuộn tới hiện vật
    // cuối để chứng minh, không thể assert cả 5 cùng lúc. Drag thẳng vào
    // ListView vì scrollUntilVisible thấy nhiều Scrollable (TextField cũng là
    // một) và không biết chọn cái nào.
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text(MockData.artifacts.last.name), findsOneWidget);
  });
}
