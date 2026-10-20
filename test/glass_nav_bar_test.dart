import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/widgets/glass_nav_bar.dart';

void main() {
  const items = [
    GlassNavItem(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Khám phá',
    ),
    GlassNavItem(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
      label: 'Bản đồ',
    ),
  ];

  testWidgets('chỉ hiện icon, không có chữ chú thích', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GlassNavBar(
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
            bottomNavigationBar: GlassNavBar(
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

  testWidgets('nút giữa nằm giữa hai nửa tab và bấm được', (tester) async {
    var tapped = 0;
    const four = [
      ...items,
      GlassNavItem(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: 'Yêu thích',
      ),
      GlassNavItem(
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
          bottomNavigationBar: GlassNavBar(
            items: four,
            currentIndex: 0,
            onTap: (_) {},
            centerButton: GlassNavCenterButton(
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
    // Nhô lên trên hàng tab.
    expect(scan.dy, lessThan(map.dy));

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    expect(tapped, 1);
  });
}
