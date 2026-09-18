import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../theme/app_theme.dart';

/// Hiển thị nội dung HTML do trình soạn thảo của trang admin sinh ra.
///
/// Admin dùng Tiptap/StarterKit nên `description` là chuỗi HTML — in đậm,
/// in nghiêng, tiêu đề, danh sách. Đổ thẳng vào [Text] thì khách nhìn thấy
/// nguyên thẻ `<p><strong>…`, nên phải parse rồi dựng lại bằng widget.
///
/// Chỉ nhận đúng tập thẻ StarterKit tạo ra; thẻ lạ được coi như nội dung
/// thường thay vì bỏ đi, để không bao giờ mất chữ của người soạn.
class RichTextContent extends StatelessWidget {
  const RichTextContent({
    super.key,
    required this.html,
    this.style = const TextStyle(
      fontSize: 15,
      height: 1.65,
      color: AppColors.textPrimary,
    ),
  });

  final String html;

  /// Kiểu chữ nền, các thẻ inline chồng thêm lên trên.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final blocks = _buildBlocks(normalizeToHtml(html), style);
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

/// Đưa giá trị thô về HTML, giống hệt `toEditorHtml` của trang admin để hai
/// bên hiển thị cùng một thứ: đã có thẻ thì giữ nguyên, còn văn bản thường thì
/// tách đoạn theo dòng trống và xuống dòng đơn thành `<br>`.
String normalizeToHtml(String value) {
  if (value.trim().isEmpty) return '';
  if (RegExp(r'<[a-z][^>]*>', caseSensitive: false).hasMatch(value)) {
    return value;
  }
  final escaped = value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  return escaped
      .split(RegExp(r'\n{2,}'))
      .map((block) => '<p>${block.replaceAll('\n', '<br>')}</p>')
      .join();
}

/// Lột hết thẻ, trả về chữ thuần — dùng cho chỗ chỉ hiện một hai dòng tóm tắt
/// (có `maxLines` + ellipsis) nên không dựng được rich text.
String htmlToPlainText(String value) {
  final normalized = normalizeToHtml(value);
  if (normalized.isEmpty) return '';
  final body = html_parser.parse(normalized).body;
  if (body == null) return '';
  // Mỗi block là một đoạn: nối bằng khoảng trắng để hai đoạn không dính liền.
  final text = body.nodes.map(_nodeText).join(' ');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _nodeText(dom.Node node) {
  if (node is dom.Text) return node.text;
  if (node is dom.Element) {
    if (node.localName == 'br') return ' ';
    return node.nodes.map(_nodeText).join();
  }
  return '';
}

const _blockTags = {
  'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
  'ul', 'ol', 'blockquote', 'pre', 'hr', 'div',
};

List<Widget> _buildBlocks(String normalizedHtml, TextStyle base) {
  if (normalizedHtml.isEmpty) return const [];
  final body = html_parser.parse(normalizedHtml).body;
  if (body == null) return const [];

  final blocks = <Widget>[];
  // Chữ nằm trần ngoài mọi thẻ (hoặc trong thẻ inline ở cấp cao nhất) vẫn phải
  // hiện, nên gom lại thành một đoạn riêng.
  final loose = <InlineSpan>[];

  void flushLoose() {
    if (loose.isEmpty) return;
    blocks.add(_paragraph(List.of(loose), base));
    loose.clear();
  }

  for (final node in body.nodes) {
    if (node is dom.Element && _blockTags.contains(node.localName)) {
      flushLoose();
      final block = _buildBlock(node, base);
      if (block != null) blocks.add(block);
    } else {
      loose.addAll(_inlineSpans(node, base));
    }
  }
  flushLoose();

  return _withSpacing(blocks);
}

/// Khoảng cách giữa các block. Đặt ở đây thay vì trong từng block để block
/// cuối không thừa padding dưới.
List<Widget> _withSpacing(List<Widget> blocks) {
  final spaced = <Widget>[];
  for (var i = 0; i < blocks.length; i++) {
    if (i > 0) spaced.add(const SizedBox(height: 12));
    spaced.add(blocks[i]);
  }
  return spaced;
}

Widget? _buildBlock(dom.Element element, TextStyle base) {
  switch (element.localName) {
    case 'hr':
      return const Divider(color: AppColors.divider, height: 1);

    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      final level = int.parse(element.localName!.substring(1));
      // h1 to nhất, càng xuống càng nhỏ, không bao giờ nhỏ hơn chữ thường.
      final size = (base.fontSize ?? 15) + (7 - level) * 1.5;
      return _paragraph(
        _childrenSpans(element, base),
        base.copyWith(fontSize: size, fontWeight: FontWeight.w700, height: 1.35),
      );

    case 'blockquote':
      return Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primaryLight, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withSpacing(_childBlocks(element, base)),
        ),
      );

    case 'pre':
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          element.text.trimRight(),
          style: base.copyWith(fontFamily: 'monospace', fontSize: 13.5),
        ),
      );

    case 'ul':
    case 'ol':
      return _list(element, base, ordered: element.localName == 'ol');

    default:
      final spans = _childrenSpans(element, base);
      // <p></p> rỗng do trình soạn thảo để lại — bỏ hẳn, không chừa khoảng trống.
      if (_isBlank(spans)) return null;
      return _paragraph(spans, base);
  }
}

/// Các block con bên trong một block (blockquote, li). Nội dung trần được gom
/// thành một đoạn như ở cấp cao nhất.
List<Widget> _childBlocks(dom.Element element, TextStyle base) {
  final blocks = <Widget>[];
  final loose = <InlineSpan>[];

  void flushLoose() {
    if (loose.isEmpty) return;
    if (!_isBlank(loose)) blocks.add(_paragraph(List.of(loose), base));
    loose.clear();
  }

  for (final node in element.nodes) {
    if (node is dom.Element && _blockTags.contains(node.localName)) {
      flushLoose();
      final block = _buildBlock(node, base);
      if (block != null) blocks.add(block);
    } else {
      loose.addAll(_inlineSpans(node, base));
    }
  }
  flushLoose();
  return blocks;
}

Widget _list(dom.Element element, TextStyle base, {required bool ordered}) {
  final items = element.children.where((e) => e.localName == 'li').toList();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  ordered ? '${i + 1}.' : '•',
                  style: base.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _withSpacing(_childBlocks(items[i], base)),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _paragraph(List<InlineSpan> spans, TextStyle style) =>
    Text.rich(TextSpan(style: style, children: spans));

List<InlineSpan> _childrenSpans(dom.Element element, TextStyle base) =>
    element.nodes.expand((n) => _inlineSpans(n, base)).toList();

List<InlineSpan> _inlineSpans(dom.Node node, TextStyle base) {
  if (node is dom.Text) {
    return node.text.isEmpty ? const [] : [TextSpan(text: node.text)];
  }
  if (node is! dom.Element) return const [];

  switch (node.localName) {
    case 'br':
      return const [TextSpan(text: '\n')];

    case 'strong':
    case 'b':
      return [
        TextSpan(
          style: const TextStyle(fontWeight: FontWeight.w700),
          children: _childrenSpans(node, base),
        ),
      ];

    case 'em':
    case 'i':
      return [
        TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: _childrenSpans(node, base),
        ),
      ];

    case 'u':
      return [
        TextSpan(
          style: const TextStyle(decoration: TextDecoration.underline),
          children: _childrenSpans(node, base),
        ),
      ];

    case 's':
    case 'del':
    case 'strike':
      return [
        TextSpan(
          style: const TextStyle(decoration: TextDecoration.lineThrough),
          children: _childrenSpans(node, base),
        ),
      ];

    case 'code':
      return [
        TextSpan(
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: (base.fontSize ?? 15) - 1.5,
            backgroundColor: AppColors.surfaceTint,
          ),
          children: _childrenSpans(node, base),
        ),
      ];

    case 'a':
      // Tô màu cho ra dáng liên kết nhưng chưa bấm được: mở URL cần thêm
      // url_launcher, và hiện chưa có chỗ nào trong nội dung dùng tới link.
      return [
        TextSpan(
          style: const TextStyle(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
          children: _childrenSpans(node, base),
        ),
      ];

    default:
      return _childrenSpans(node, base);
  }
}

bool _isBlank(List<InlineSpan> spans) =>
    spans.every((s) => s.toPlainText().trim().isEmpty);
