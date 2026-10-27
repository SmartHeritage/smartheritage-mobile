import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/widgets/app_nav_bar.dart';

void main() {
  const items = [
    AppNavItem(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Khám phá',
    ),
    AppNavItem(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
      label: 'Bản đồ',
    ),
  ];

  testWidgets('chỉ hiện icon, không có chữ chú thích', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppNavBar(
            items: items,
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Bản đồ'), findsNothing);
    expect(find.bySemanticsLabel('Bản đồ'), findsOneWidget);
  });

  testWidgets('bấm tab thì báo đúng chỉ số, tab đang chọn dùng icon đậm', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: AppNavBar(
              items: items,
              currentIndex: index,
              onTap: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.explore), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Bản đồ'));
    await tester.pumpAndSettle();

    expect(index, 1);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
  });

  testWidgets('khối chọn trượt sang tab mới', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: AppNavBar(
              items: items,
              currentIndex: index,
              onTap: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );
    double indicatorX() => tester.getCenter(find.byType(AnimatedPositioned)).dx;
    final before = indicatorX();
    expect(
      before,
      moreOrLessEquals(
        tester.getCenter(find.byIcon(Icons.explore)).dx,
        epsilon: 1,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Bản đồ'));
    await tester.pump(); // dựng lại với tab mới — hoạt ảnh bắt đầu từ đây
    await tester.pump(const Duration(milliseconds: 100));
    // Đang trượt: đã rời tab cũ nhưng chưa tới tab mới.
    final midway = indicatorX();
    final target = tester.getCenter(find.byIcon(Icons.map)).dx;
    expect(midway, greaterThan(before));
    expect(midway, lessThan(target));

    await tester.pumpAndSettle();
    expect(indicatorX(), moreOrLessEquals(target, epsilon: 1));
  });

  testWidgets('nút giữa nằm giữa hai nửa tab và bấm được', (tester) async {
    var tapped = 0;
    const four = [
      ...items,
      AppNavItem(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: 'Yêu thích',
      ),
      AppNavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Cá nhân',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: AppNavBar(
            items: four,
            currentIndex: 0,
            onTap: (_) {},
            centerButton: AppNavCenterButton(
              icon: Icons.qr_code_scanner,
              label: 'Quét',
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );

    final scan = tester.getCenter(find.byIcon(Icons.qr_code_scanner));
    final map = tester.getCenter(find.byIcon(Icons.map_outlined));
    final fav = tester.getCenter(find.byIcon(Icons.favorite_border));
    expect(scan.dx, greaterThan(map.dx));
    expect(scan.dx, lessThan(fav.dx));
    // Mặc định (đang có mini-player) nằm gọn trong thanh, cùng hàng với các tab.
    expect(scan.dy, moreOrLessEquals(map.dy, epsilon: 1));

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    expect(tapped, 1);

    // Không có mini-player: to hơn, trồi lên khỏi hàng tab, vẫn bấm được.
    final smallSize = tester.getSize(find.bySemanticsLabel('Quét')).width;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: AppNavBar(
            items: four,
            currentIndex: 0,
            onTap: (_) {},
            raiseCenter: true,
            centerButton: AppNavCenterButton(
              icon: Icons.qr_code_scanner,
              label: 'Quét',
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final raised = tester.getCenter(find.byIcon(Icons.qr_code_scanner));
    final mapAfter = tester.getCenter(find.byIcon(Icons.map_outlined));
    expect(raised.dy, lessThan(mapAfter.dy - 10));
    expect(
      tester.getSize(find.bySemanticsLabel('Quét')).width,
      greaterThan(smallSize),
    );
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    expect(tapped, 2);
  });
}
