import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/data/review_repository.dart';
import 'package:smartheritage/screens/feedback/feedback_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

const _base = 'http://test.local/api/v1';
const _uuid = 'a0d60f48-699d-4db9-9d64-36847afeeb2a';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _apiReview({
  String id = 'r1',
  int rating = 4,
  List<String> tags = const ['content_good'],
  String? comment = 'Rất đáng xem.',
}) =>
    {
      'id': id,
      'userId': 'u1',
      'artifactId': _uuid,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'status': 'approved',
      'createdAt': '2026-09-17T19:36:02.622Z',
    };

/// Hiện vật mang id UUID như dữ liệu thật, không phải 'a1' của bản mock.
Artifact _artifact() {
  final base = MockData.artifacts.first;
  return Artifact(
    id: _uuid,
    name: base.name,
    era: base.era,
    zone: base.zone,
    shortIntro: base.shortIntro,
    description: base.description,
    icon: base.icon,
    gradient: base.gradient,
    rating: base.rating,
    reviewCount: base.reviewCount,
    audioDuration: base.audioDuration,
    videoDuration: base.videoDuration,
  );
}

ReviewRepository _repo(MockClient mock) =>
    ReviewRepository(api: ApiClient(httpClient: mock, baseUrl: _base));

void main() {
  group('ReviewRepository', () {
    test('đọc đánh giá đã duyệt của hiện vật', () async {
      Uri? seen;
      final repo = _repo(MockClient((req) async {
        seen = req.url;
        return _json([_apiReview(), _apiReview(id: 'r2', rating: 5)]);
      }));

      final reviews = await repo.listForArtifact(_uuid);

      expect(seen?.path, '/api/v1/reviews');
      expect(seen?.queryParameters['artifactId'], _uuid);
      expect(reviews.map((r) => r.rating), [4, 5]);
      expect(reviews.first.tagLabels, ['Nội dung hấp dẫn']);
    });

    test('id mock thì không gọi mạng — GET /reviews đòi UUID và sẽ 400',
        () async {
      var called = false;
      final repo = _repo(MockClient((_) async {
        called = true;
        return _json([]);
      }));

      final reviews = await repo.listForArtifact('a1');

      expect(called, isFalse);
      expect(reviews, isEmpty);
    });

    test('gửi đánh giá kèm tag và nội dung', () async {
      Map<String, dynamic>? body;
      final repo = _repo(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({}, 201);
      }));

      await repo.submit(
        artifactId: _uuid,
        rating: 5,
        tags: const ['content_good', 'narration_clear'],
        comment: '  Rất hay.  ',
      );

      expect(body, {
        'rating': 5,
        'artifactId': _uuid,
        'tags': ['content_good', 'narration_clear'],
        'comment': 'Rất hay.',
      });
    });

    test('không tag, không nội dung thì chỉ gửi rating', () async {
      Map<String, dynamic>? body;
      final repo = _repo(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({}, 201);
      }));

      await repo.submit(artifactId: _uuid, rating: 3, comment: '   ');

      expect(body, {'rating': 3, 'artifactId': _uuid});
    });

    test('góp ý chung cho khu di tích thì bỏ artifactId', () async {
      Map<String, dynamic>? body;
      final repo = _repo(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({}, 201);
      }));

      await repo.submit(rating: 4);

      expect(body!.containsKey('artifactId'), isFalse);
      expect(body!['rating'], 4);
    });

    test('id mock cũng không kèm artifactId, tránh 400', () async {
      Map<String, dynamic>? body;
      final repo = _repo(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({}, 201);
      }));

      await repo.submit(artifactId: 'a1', rating: 4);

      expect(body!.containsKey('artifactId'), isFalse);
    });

    test('lỗi mạng ném ApiException cho màn hình bắt', () async {
      final repo = _repo(MockClient((_) async {
        throw const SocketException('mat mang');
      }));

      await expectLater(
        repo.submit(rating: 4),
        throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', isTrue)),
      );
    });

    test('bỏ qua mã tag lạ thay vì vỡ màn hình', () {
      final review = Review.fromJson(
        _apiReview(tags: const ['content_good', 'tag_moi_cua_backend']),
      );

      expect(review.tags.length, 2);
      expect(review.tagLabels, ['Nội dung hấp dẫn']);
    });
  });

  group('tab Đánh giá', () {
    setUp(() => AuthController.instance.setTestSession());
    tearDown(() {
      AuthController.instance.resetForTest();
      ReviewRepository.instance = ReviewRepository();
    });

    Widget harness() => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: ArtifactReviewsTab(artifact: _artifact())),
        );

    testWidgets('hiện đánh giá thật kèm sao, tag và nội dung', (tester) async {
      ReviewRepository.instance = _repo(MockClient(
          (_) async => _json([_apiReview(rating: 4, comment: 'Rất đáng xem.')])));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.text('Đánh giá của khách tham quan (1)'), findsOneWidget);
      expect(find.text('Rất đáng xem.'), findsOneWidget);
      expect(find.text('Nội dung hấp dẫn'), findsWidgets);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    });

    testWidgets('chưa có đánh giá thì mời là người đầu tiên', (tester) async {
      ReviewRepository.instance = _repo(MockClient((_) async => _json([])));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(
        find.text('Chưa có đánh giá nào. Hãy là người đầu tiên!'),
        findsOneWidget,
      );
      // Vẫn gửi được đánh giá mới.
      expect(find.text('Gửi phản hồi'), findsOneWidget);
    });

    testWidgets('tải danh sách hỏng vẫn cho gửi đánh giá', (tester) async {
      ReviewRepository.instance = _repo(MockClient((req) async {
        if (req.method == 'GET') throw const SocketException('mat mang');
        return _json({}, 201);
      }));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.text('Chưa tải được danh sách đánh giá.'), findsOneWidget);
      expect(find.text('Gửi phản hồi'), findsOneWidget);
    });

    testWidgets('gửi xong thì nạp lại danh sách', (tester) async {
      var posted = false;
      ReviewRepository.instance = _repo(MockClient((req) async {
        if (req.method == 'POST') {
          posted = true;
          return _json({}, 201);
        }
        // Lần đầu chưa có gì; sau khi gửi thì danh sách có một đánh giá.
        return _json(posted ? [_apiReview(comment: 'Vừa gửi xong.')] : []);
      }));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(find.text('Vừa gửi xong.'), findsNothing);

      await tester.ensureVisible(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gửi phản hồi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi phản hồi'));
      await tester.pumpAndSettle();

      expect(posted, isTrue);
      // POST /reviews mặc định vào thẳng 'approved' nên phải thấy được ngay.
      expect(find.text('Vừa gửi xong.'), findsOneWidget);
    });

    testWidgets('gửi hỏng thì báo lỗi đỏ, không báo cảm ơn', (tester) async {
      ReviewRepository.instance = _repo(MockClient((req) async {
        if (req.method == 'POST') {
          return _json({'message': 'Máy chủ gặp sự cố'}, 500);
        }
        return _json([]);
      }));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gửi phản hồi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi phản hồi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Máy chủ gặp sự cố'), findsOneWidget);
      expect(
        find.text('Cảm ơn bạn! Phản hồi đã được gửi thành công.'),
        findsNothing,
      );
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, AppColors.danger);
    });
  });
}
