import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/home/home_screen.dart';
import 'package:smartheritage/screens/main_shell.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

void main() {
  tearDown(() => BeaconScanController.instance.stopScan());

  /// Chỗ cuộn của danh sách chính trên trang chủ.
  double homeOffset(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(HomeScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position
      .pixels;

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MainShell()),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollHomeDown(WidgetTester tester) async {
    await tester.drag(
      find
          .descendant(
            of: find.byType(HomeScreen),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(homeOffset(tester), greaterThan(0));
  }

  testWidgets('đổi tab rồi quay lại thì trang về đầu', (tester) async {
    await pumpShell(tester);
    await scrollHomeDown(tester);

    await tester.tap(find.bySemanticsLabel('Yêu thích'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Khám phá'));
    await tester.pumpAndSettle();

    expect(homeOffset(tester), 0);
  });

  testWidgets('bấm lại tab đang mở thì cuộn lên đầu', (tester) async {
    await pumpShell(tester);
    await scrollHomeDown(tester);

    await tester.tap(find.bySemanticsLabel('Khám phá'));
    await tester.pumpAndSettle();

    expect(homeOffset(tester), 0);
  });
}
