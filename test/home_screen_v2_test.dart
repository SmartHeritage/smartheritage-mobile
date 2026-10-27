import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartheritage/data/news_repository.dart';
import 'package:smartheritage/screens/favorites/favorites_screen.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/screens/map/map_screen.dart';
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
        'Giới thiệu',
        'Lịch sử',
        'Góp ý',
        'Trợ giúp',
        'Cài đặt',
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

  testWidgets('ô Bản đồ và Yêu thích mở trang riêng, không chuyển tab',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreenV2()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Tab thứ hai/thứ ba giờ là Danh sách nghe và Thông báo.
    await tester.tap(find.text('Yêu thích'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bản đồ'));
    await tester.pumpAndSettle();
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets('ô lưới nhún khi nhấn và rung nhẹ khi bấm, không có vệt loang',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreenV2()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    double scaleOf(String label) => tester
        .widget<AnimatedScale>(find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(GestureDetector),
          ).first,
          matching: find.byType(AnimatedScale),
        ))
        .scale;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Giới thiệu')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(scaleOf('Giới thiệu'), 0.9);

    await gesture.up();
    await tester.pump();
    expect(scaleOf('Giới thiệu'), 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await tester.pumpAndSettle();

    // Không còn InkWell trong ô lưới.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: find.text('Lịch sử'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });
}
