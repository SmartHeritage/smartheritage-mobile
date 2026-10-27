import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/data/review_repository.dart';
import 'package:smartheritage/screens/artifact/artifact_detail_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/audio_player_state.dart';

import 'support/fake_audio_player.dart';

/// Tài liệu DETAIL như admin soạn trong Tiptap: "Trống **đồng** *cổ*".
const _formatted = {
  'type': 'doc',
  'content': [
    {
      'type': 'paragraph',
      'content': [
        {'type': 'text', 'text': 'Trống '},
        {
          'type': 'text',
          'text': 'đồng',
          'marks': [
            {'type': 'bold'},
          ],
        },
        {
          'type': 'text',
          'text': ' cổ',
          'marks': [
            {'type': 'italic'},
          ],
        },
      ],
    },
  ],
};

Map<String, dynamic> _json({
  String description = 'Trống đồng cổ',
  Object? doc,
}) => {
  // Không trùng id hiện vật mẫu ('a1'…): trang chi tiết lấy lại bản mới nhất
  // theo id từ kho, trùng thì nó hiện mô tả của hiện vật mẫu.
  'id': 'rich-1',
  'name': 'Hiện vật thử',
  'description': description,
  'descriptionJson': ?doc,
};

/// Mọi đoạn chữ lá trong các RichText đang hiển thị, kèm kiểu chữ đã cộng dồn
/// từ các span cha — `<strong>` đặt kiểu đậm ở span cha, span lá không tự mang.
Iterable<(String, TextStyle)> _spans(WidgetTester tester) sync* {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final stack = <(InlineSpan, TextStyle)>[(rich.text, const TextStyle())];
    while (stack.isNotEmpty) {
      final (span, inherited) = stack.removeLast();
      if (span is! TextSpan) continue;
      final style = inherited.merge(span.style);
      if (span.text case final text?) yield (text, style);
      for (final child in span.children ?? const <InlineSpan>[]) {
        stack.add((child, style));
      }
    }
  }
}

void main() {
  group('Artifact.fromJson — descriptionJson', () {
    test('có Tiptap JSON thì mô tả là HTML giữ in đậm, in nghiêng', () {
      final a = Artifact.fromJson(_json(doc: _formatted));
      expect(a.description, '<p>Trống <strong>đồng</strong><em> cổ</em></p>');
    });

    test('backend cũ không có descriptionJson thì giữ chữ thuần', () {
      expect(Artifact.fromJson(_json()).description, 'Trống đồng cổ');
    });

    test('không có bản cho ngôn ngữ này (chữ thuần rỗng) thì vẫn rỗng', () {
      final a = Artifact.fromJson(
        _json(description: '', doc: const {'type': 'doc', 'content': []}),
      );
      expect(a.description, isEmpty);
    });
  });

  testWidgets('trang chi tiết vẽ đúng chữ in đậm và in nghiêng', (
    tester,
  ) async {
    AudioPlayerController.instance = AudioPlayerController(
      player: FakeAudioPlayer(),
    );
    ReviewRepository.instance = ReviewRepository(
      api: ApiClient(
        baseUrl: 'http://test.local/api/v1',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      ),
    );
    addTearDown(() => ReviewRepository.instance = ReviewRepository());
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final base = MockData.artifacts.first;
    final artifact = Artifact.fromJson({
      ..._json(doc: _formatted),
      'name': base.name,
    });
    await tester.pumpWidget(
      MaterialApp(home: ArtifactDetailScreen(artifact: artifact)),
    );
    await tester.pump();

    final spans = _spans(tester).toList();
    final bold = spans.firstWhere((s) => s.$1 == 'đồng');
    final italic = spans.firstWhere((s) => s.$1 == ' cổ');
    expect(bold.$2.fontWeight, FontWeight.w700);
    expect(italic.$2.fontStyle, FontStyle.italic);
  });
}
