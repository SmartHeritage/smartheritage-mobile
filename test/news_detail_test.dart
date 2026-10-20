import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/news_repository.dart';
import 'package:smartheritage/data/tiptap.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/screens/news/news_detail_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/theme/app_theme.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

const _title = 'Mở cửa trưng bày chuyên đề "Gốm Việt qua các triều đại"';

final _doc = {
  'type': 'doc',
  'content': [
    {
      'type': 'heading',
      'attrs': {'level': 2},
      'content': [
        {'type': 'text', 'text': 'Điểm nhấn'},
      ],
    },
    {
      'type': 'paragraph',
      'content': [
        {'type': 'text', 'text': 'Hơn 80 hiện vật '},
        {
          'type': 'text',
          'text': 'gốm hoa nâu',
          'marks': [
            {'type': 'bold'},
          ],
        },
        {'type': 'text', 'text': ' thời Trần.'},
      ],
    },
  ],
};

void main() {
  late List<String> calls;

  NewsRepository repo({bool detailMissing = false}) => NewsRepository(
    api: ApiClient(
      baseUrl: _base,
      httpClient: MockClient((req) async {
        calls.add('${req.url.path}?${req.url.query}');
        final path = req.url.path;
        if (path.endsWith('/blogs')) {
          return _json({
            'items': [
              {
                'id': 'b1',
                'slug': 'gom-viet',
                'languageCode': 'vi',
                'title': _title,
                'publishedAt': '2026-09-24T03:00:00.000Z',
                'featuredImageUrl': null,
              },
              // Thiếu slug thì không mở được — bỏ qua.
              {'id': 'b2', 'slug': '', 'title': 'Bài lỗi'},
            ],
            'total': 2,
            'page': 1,
            'limit': 10,
          });
        }
        if (path.endsWith('/blogs/gom-viet')) {
          if (detailMissing) return _json({'message': 'Blog not found'}, 404);
          return _json({
            'id': 'b1',
            'slug': 'gom-viet',
            'title': _title,
            'contentJson': _doc,
          });
        }
        return _json({'message': 'not found'}, 404);
      }),
    ),
  )..language = 'vi';

  setUp(() => calls = []);
  tearDown(() => NewsRepository.instance = NewsRepository());

  group('NewsRepository', () {
    test('đọc danh sách bài đã xuất bản theo ngôn ngữ', () async {
      final news = repo();
      await news.refresh();

      expect(calls.single, '/api/v1/blogs?lang=vi&limit=10');
      expect(news.items.map((n) => n.title), [_title]);
      expect(news.items.single.dateLabel, '24/09/2026');
      expect(news.items.single.imageUrl, isNull);
    });
  });

  group('tiptapToHtml', () {
    test('dựng thẻ HTML và định dạng chữ', () {
      expect(
        tiptapToHtml(_doc),
        '<h2>Điểm nhấn</h2>'
        '<p>Hơn 80 hiện vật <strong>gốm hoa nâu</strong> thời Trần.</p>',
      );
    });

    test('thoát ký tự HTML, node lạ vẫn giữ chữ, dữ liệu hỏng ra rỗng', () {
      expect(
        tiptapToHtml({
          'type': 'doc',
          'content': [
            {
              'type': 'callout',
              'content': [
                {'type': 'text', 'text': 'a < b & c'},
              ],
            },
          ],
        }),
        'a &lt; b &amp; c',
      );
      expect(tiptapToHtml(null), '');
      expect(tiptapToHtml('rác'), '');
    });
  });

  testWidgets('bấm thẻ tin ở trang chủ thì mở bài và tải nội dung', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final news = repo();
    await tester.runAsync(news.refresh);
    NewsRepository.instance = news;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeScreenV2()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tin tức'), findsOneWidget);
    expect(find.text('Bài lỗi'), findsNothing);

    await tester.tap(find.text(_title));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(NewsDetailScreen), findsOneWidget);
    expect(find.text('24/09/2026'), findsOneWidget);
    expect(find.text('Điểm nhấn'), findsOneWidget);
    expect(calls, contains('/api/v1/blogs/gom-viet?lang=vi'));
  });

  testWidgets('chưa có bài nào thì trang chủ ẩn mục Tin tức', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    NewsRepository.instance = NewsRepository()..setItemsForTest(const []);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeScreenV2()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tin tức'), findsNothing);
  });

  testWidgets('bài đã bị gỡ thì báo rõ, có nút thử lại và quay về được', (
    tester,
  ) async {
    final news = repo(detailMissing: true);
    await tester.runAsync(news.refresh);
    NewsRepository.instance = news;
    final item = news.items.single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewsDetailScreen(item: item),
                  ),
                ),
                child: const Text('MỞ'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('MỞ'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text(_title), findsOneWidget);
    expect(find.textContaining('Bài viết này không còn'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.byType(NewsDetailScreen), findsNothing);
    expect(find.text('MỞ'), findsOneWidget);
  });
}
