import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/data/news_repository.dart';
import 'package:smartheritage/screens/auth/login_screen.dart';
import 'package:smartheritage/screens/news/news_detail_screen.dart';
import 'package:smartheritage/screens/notification/news_inbox_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/news_inbox_state.dart';
import 'package:smartheritage/widgets/app_nav_bar.dart';

NewsItem _post(String id, DateTime publishedAt) => NewsItem(
  id: id,
  slug: 'bai-$id',
  title: 'Bài $id',
  publishedAt: publishedAt,
);

void main() {
  final auth = AuthController.instance;
  late NewsRepository news;
  late NewsInboxController inbox;
  late NewsRepository originalNews;

  /// Bài cũ đăng trước khi tài khoản dùng tab; bài mới đăng sau đó.
  final old = _post('old', DateTime(2020));
  final fresh = _post('new', DateTime.now().add(const Duration(days: 1)));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth.resetForTest();
    // Trang bài viết tự tải nội dung qua NewsRepository.instance — trả nội
    // dung giả, không đụng mạng thật.
    news = NewsRepository(
      api: ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"contentJson": {"type": "doc", "content": []}}',
            200,
            headers: const {'content-type': 'application/json'},
          ),
        ),
        baseUrl: 'http://test.local/api/v1',
      ),
    )..setItemsForTest([fresh, old]);
    originalNews = NewsRepository.instance;
    NewsRepository.instance = news;
    inbox = NewsInboxController(news: news, auth: auth);
    NewsInboxController.instance = inbox;
  });

  tearDown(() {
    NewsRepository.instance = originalNews;
    inbox.dispose();
    auth.resetForTest();
  });

  group('NewsInboxController', () {
    test('khách: không có bài, không có chấm đỏ', () {
      expect(inbox.items, isEmpty);
      expect(inbox.unreadCount, 0);
    });

    test('đăng nhập: chỉ bài đăng sau lần đầu dùng mới tính là mới', () async {
      auth.setTestSession();
      await pumpEventQueue();

      expect(inbox.items, hasLength(2));
      expect(inbox.isUnread(fresh), isTrue);
      expect(inbox.isUnread(old), isFalse);
      expect(inbox.unreadCount, 1);
    });

    test('đã đọc lưu theo tài khoản, mở lại app vẫn nhớ', () async {
      auth.setTestSession();
      await pumpEventQueue();
      inbox.markRead(fresh);
      expect(inbox.unreadCount, 0);
      await pumpEventQueue();

      // Như mở lại app: controller mới đọc lại từ bộ nhớ máy.
      final again = NewsInboxController(news: news, auth: auth);
      addTearDown(again.dispose);
      await pumpEventQueue();
      expect(again.isUnread(fresh), isFalse);

      // Đã đọc là theo từng tài khoản: tài khoản khác vẫn thấy bài đó mới.
      auth.setTestSession(id: 'nguoi-khac');
      await pumpEventQueue();
      expect(again.isUnread(fresh), isTrue);
      expect(again.isUnread(old), isFalse);
    });

    test('đánh dấu tất cả đã đọc', () async {
      auth.setTestSession();
      await pumpEventQueue();
      inbox.markAllRead();
      expect(inbox.unreadCount, 0);
    });
  });

  group('NewsInboxScreen', () {
    testWidgets('khách thấy lời mời đăng nhập', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewsInboxScreen()));
      expect(find.text('Đăng nhập để nhận thông báo'), findsOneWidget);
      expect(find.text('Bài new'), findsNothing);

      await tester.tap(find.text('Đăng nhập / Đăng ký'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('bài mới có nhãn Mới, bấm vào thì mở bài và hết mới', (
      tester,
    ) async {
      auth.setTestSession();
      await tester.runAsync(pumpEventQueue);
      await tester.pumpWidget(const MaterialApp(home: NewsInboxScreen()));
      await tester.pump();

      expect(find.text('Bài new'), findsOneWidget);
      expect(find.text('Bài old'), findsOneWidget);
      expect(find.text('Mới'), findsOneWidget);

      await tester.tap(find.text('Bài new'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(NewsDetailScreen), findsOneWidget);
      expect(inbox.unreadCount, 0);
    });
  });

  testWidgets('thanh điều hướng hiện chấm số trên tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppNavBar(
            currentIndex: 0,
            onTap: (_) {},
            items: const [
              AppNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Trang chủ',
              ),
              AppNavItem(
                icon: Icons.notifications_none_rounded,
                selectedIcon: Icons.notifications_rounded,
                label: 'Thông báo',
                badgeCount: 12,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('9+'), findsOneWidget);
  });
}
