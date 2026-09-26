import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/screens/news/news_detail_screen.dart';
import 'package:smartheritage/theme/app_theme.dart';

void main() {
  final first = MockData.news.first;

  testWidgets('bấm thẻ tin ở trang chủ thì mở trang chi tiết', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreenV2()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();

    expect(find.byType(NewsDetailScreen), findsOneWidget);
    expect(find.text(first.dateLabel), findsOneWidget);
    expect(find.text(first.summary), findsOneWidget);
  });

  testWidgets('trang chi tiết có nút back và quay về được', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(item: first),
                ),
              ),
              child: const Text('MỞ'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('MỞ'));
    await tester.pumpAndSettle();
    expect(find.text(first.title), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.byType(NewsDetailScreen), findsNothing);
    expect(find.text('MỞ'), findsOneWidget);
  });
}
