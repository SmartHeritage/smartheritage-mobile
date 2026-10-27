import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/app_info.dart';
import 'package:smartheritage/screens/about/about_screen.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/theme/app_theme.dart';

void main() {
  testWidgets('ô Giới thiệu ở lưới trang chủ mở trang Giới thiệu',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreenV2()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đang nghe'), findsNothing);

    await tester.tap(find.text('Giới thiệu'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('có banner, tên app, các mục chữ và phiên bản; cuộn không lỗi',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const AboutScreen(),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              'assets/images/hero_museum.jpg'),
      findsOneWidget,
    );
    expect(find.text('Smart Heritage'), findsOneWidget);
    expect(find.text('Về Smart Heritage'), findsOneWidget);
    // Mục sau nằm dưới màn hình đầu — cuộn tới mới được dựng.
    await tester.scrollUntilVisible(
      find.text('Bạn có thể làm gì'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bạn có thể làm gì'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Phiên bản ${AppInfo.version}'), findsOneWidget);
    // Khối tên ghim lại dưới thanh trên khi đã cuộn.
    expect(find.text('Smart Heritage'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  });

  testWidgets('máy hẹp 320pt không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const AboutScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
