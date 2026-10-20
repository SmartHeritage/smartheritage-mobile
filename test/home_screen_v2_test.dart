import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartheritage/data/news_repository.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/theme/app_theme.dart';

void main() {
  for (final size in const [Size(320, 700), Size(390, 844), Size(428, 926)]) {
    testWidgets('lưới 8 ô không tràn ở ${size.width.toInt()}pt',
        (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeScreenV2()),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      for (final label in const [
        'Bản đồ',
        'Quét beacon',
        'Yêu thích',
        'Đang nghe',
        'Lịch sử',
        'Góp ý',
        'Trợ giúp',
        'Tài khoản',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu ô $label');
      }

    });
  }

  testWidgets('có đủ hai dải carousel Nổi bật và Tin tức', (tester) async {
    // Khung cao để ListView dựng tới cuối trang, khỏi phải cuộn.
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    // Tin tức chỉ hiện khi backend có bài — nạp sẵn một bài.
    NewsRepository.instance = NewsRepository()
      ..setItemsForTest(const [
        NewsItem(id: 'b1', slug: 'gom-viet', title: 'Trưng bày gốm Việt'),
      ]);
    addTearDown(() => NewsRepository.instance = NewsRepository());

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreenV2()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nổi bật'), findsOneWidget);
    expect(find.text('Tin tức'), findsOneWidget);
    // Tin tức phải nằm dưới Nổi bật.
    final noiBat = tester.getTopLeft(find.text('Nổi bật')).dy;
    final tinTuc = tester.getTopLeft(find.text('Tin tức')).dy;
    expect(tinTuc, greaterThan(noiBat));
  });

  testWidgets('ô Bản đồ / Yêu thích chuyển tab thay vì mở màn mới',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final opened = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: HomeScreenV2(onOpenTab: opened.add)),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Bản đồ'));
    await tester.pump();
    await tester.tap(find.text('Yêu thích'));
    await tester.pump();

    expect(opened, [1, 2]);
    // Không push route nào: vẫn đứng ở trang chủ.
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
