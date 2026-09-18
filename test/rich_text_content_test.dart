import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/widgets/rich_text_content.dart';

Widget _harness(String html) => MaterialApp(
      home: Scaffold(body: RichTextContent(html: html)),
    );

/// Gom mọi span của các đoạn đang hiện, kèm kiểu chữ đã tính.
List<InlineSpan> _spans(WidgetTester tester) {
  final spans = <InlineSpan>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final span = text.textSpan;
    if (span != null) spans.add(span);
  }
  return spans;
}

/// Kiểu chữ **hiệu dụng** của đoạn văn bản khớp [needle].
///
/// Style nằm ở span bọc ngoài, span mang chữ thường có `style: null` — nên
/// phải cộng dồn từ gốc xuống giống cách Flutter dựng, không thể đọc thẳng
/// `style` của span chứa chữ.
TextStyle? _styleOf(WidgetTester tester, String needle) {
  TextStyle? search(InlineSpan span, TextStyle? inherited) {
    if (span is! TextSpan) return null;
    final merged =
        inherited == null ? span.style : inherited.merge(span.style);
    if ((span.text ?? '').contains(needle)) return merged;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final hit = search(child, merged);
      if (hit != null) return hit;
    }
    return null;
  }

  for (final span in _spans(tester)) {
    final hit = search(span, null);
    if (hit != null) return hit;
  }
  return null;
}

String _plainText(WidgetTester tester) =>
    _spans(tester).map((s) => s.toPlainText()).join('\n');

void main() {
  group('render HTML của trình soạn thảo admin', () {
    testWidgets('<strong> hiện in đậm, không hiện nguyên thẻ', (tester) async {
      // Chuỗi thật lấy từ hiện vật "Súng thần công" trong DB.
      await tester.pumpWidget(_harness(
        '<p><strong>Khẩu súng thần công bằng đồng.</strong></p><p></p>',
      ));

      expect(find.textContaining('<strong>'), findsNothing);
      expect(_plainText(tester), contains('Khẩu súng thần công bằng đồng.'));
      expect(_styleOf(tester, 'Khẩu súng')?.fontWeight, FontWeight.w700);
    });

    testWidgets('<p></p> rỗng ở cuối không tạo đoạn thừa', (tester) async {
      await tester.pumpWidget(_harness('<p>Một đoạn.</p><p></p>'));

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('in nghiêng, gạch chân và gạch ngang', (tester) async {
      await tester.pumpWidget(_harness(
        '<p><em>nghiêng</em> <u>gạch chân</u> <s>bỏ</s></p>',
      ));

      expect(_styleOf(tester, 'nghiêng')?.fontStyle, FontStyle.italic);
      expect(_styleOf(tester, 'gạch chân')?.decoration,
          TextDecoration.underline);
      expect(_styleOf(tester, 'bỏ')?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('lồng nhau: đậm bên trong nghiêng giữ cả hai', (tester) async {
      await tester.pumpWidget(_harness('<p><em>ngoài <strong>trong</strong></em></p>'));

      // "trong" phải vừa đậm vừa nghiêng: đậm từ <strong>, nghiêng thừa
      // hưởng từ <em> bọc ngoài.
      final inner = _styleOf(tester, 'trong');
      expect(inner?.fontWeight, FontWeight.w700);
      expect(inner?.fontStyle, FontStyle.italic);
      // "ngoài" chỉ nghiêng, không đậm lây.
      final outer = _styleOf(tester, 'ngoài');
      expect(outer?.fontStyle, FontStyle.italic);
      expect(outer?.fontWeight, isNot(FontWeight.w700));
    });

    testWidgets('tiêu đề h3 to và đậm hơn chữ thường', (tester) async {
      await tester.pumpWidget(_harness('<h3>Tiêu đề</h3><p>Nội dung</p>'));

      final heading = tester.widgetList<Text>(find.byType(Text)).first;
      expect(heading.textSpan?.style?.fontWeight, FontWeight.w700);
      expect(heading.textSpan?.style?.fontSize, greaterThan(15));
    });

    testWidgets('danh sách không thứ tự có dấu chấm đầu dòng', (tester) async {
      await tester.pumpWidget(_harness('<ul><li>Một</li><li>Hai</li></ul>'));

      expect(find.text('•'), findsNWidgets(2));
      expect(_plainText(tester), contains('Một'));
      expect(_plainText(tester), contains('Hai'));
    });

    testWidgets('danh sách có thứ tự đánh số 1. 2.', (tester) async {
      await tester.pumpWidget(_harness('<ol><li>Một</li><li>Hai</li></ol>'));

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
    });

    testWidgets('<br> xuống dòng trong cùng một đoạn', (tester) async {
      await tester.pumpWidget(_harness('<p>Dòng một<br>Dòng hai</p>'));

      expect(find.byType(Text), findsOneWidget);
      expect(_plainText(tester), 'Dòng một\nDòng hai');
    });

    testWidgets('thẻ lạ vẫn giữ lại chữ bên trong', (tester) async {
      await tester.pumpWidget(_harness('<p>trước <span>giữa</span> sau</p>'));

      expect(_plainText(tester), contains('trước giữa sau'));
    });

    testWidgets('chuỗi rỗng không dựng gì', (tester) async {
      await tester.pumpWidget(_harness('   '));

      expect(find.byType(Text), findsNothing);
    });
  });

  group('văn bản thuần (hiện vật chưa soạn bằng editor)', () {
    testWidgets('vẫn hiện bình thường', (tester) async {
      await tester.pumpWidget(_harness('Trống đồng Đông Sơn là hiện vật.'));

      expect(_plainText(tester), 'Trống đồng Đông Sơn là hiện vật.');
    });

    testWidgets('dòng trống tách thành hai đoạn', (tester) async {
      await tester.pumpWidget(_harness('Đoạn một.\n\nĐoạn hai.'));

      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('dấu < trong chữ thuần không bị nuốt', (tester) async {
      await tester.pumpWidget(_harness('Cao < 10cm và > 5cm'));

      expect(_plainText(tester), 'Cao < 10cm và > 5cm');
    });
  });

  group('htmlToPlainText', () {
    test('lột thẻ, giữ chữ', () {
      expect(
        htmlToPlainText('<p><strong>Khẩu súng</strong> thần công.</p>'),
        'Khẩu súng thần công.',
      );
    });

    test('hai đoạn không dính vào nhau', () {
      expect(
        htmlToPlainText('<p>Đoạn một.</p><p>Đoạn hai.</p>'),
        'Đoạn một. Đoạn hai.',
      );
    });

    test('giải mã ký tự HTML', () {
      expect(htmlToPlainText('<p>A &amp; B &lt; C</p>'), 'A & B < C');
    });

    test('văn bản thuần trả về chính nó', () {
      expect(htmlToPlainText('Chữ thường.'), 'Chữ thường.');
    });

    test('chuỗi rỗng trả về rỗng', () {
      expect(htmlToPlainText('   '), '');
    });
  });

  group('normalizeToHtml khớp toEditorHtml của admin', () {
    test('đã có thẻ thì giữ nguyên', () {
      expect(normalizeToHtml('<p>x</p>'), '<p>x</p>');
    });

    test('chữ thuần thành <p>, xuống dòng đơn thành <br>', () {
      expect(normalizeToHtml('a\nb\n\nc'), '<p>a<br>b</p><p>c</p>');
    });

    test('escape ký tự đặc biệt', () {
      expect(normalizeToHtml('a & b'), '<p>a &amp; b</p>');
    });
  });
}
