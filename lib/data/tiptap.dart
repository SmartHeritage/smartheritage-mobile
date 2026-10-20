/// Chuyển tài liệu Tiptap/ProseMirror JSON (nội dung bài viết của backend)
/// sang HTML để `RichTextContent` dựng — widget đó vốn đọc HTML mà trình soạn
/// thảo admin sinh ra cho mô tả hiện vật, nên hai nơi hiển thị giống nhau.
///
/// Admin chỉ bật StarterKit (đoạn, tiêu đề 2–3, danh sách, trích dẫn, đậm,
/// nghiêng, gạch ngang). Node lạ thì vẫn lấy chữ bên trong thay vì bỏ đi, để
/// không bao giờ mất chữ của người soạn. Không bao giờ ném lỗi: dữ liệu hỏng
/// thì ra chuỗi rỗng.
library;

String tiptapToHtml(Object? doc) {
  final out = StringBuffer();
  _node(doc, out);
  return out.toString();
}

void _node(Object? node, StringBuffer out) {
  if (node is! Map) return;
  final type = node['type'];
  if (type == 'text') {
    _text(node, out);
    return;
  }
  final attrs = node['attrs'] is Map ? node['attrs'] as Map : const {};
  final tag = switch (type) {
    'paragraph' => 'p',
    'heading' => switch (attrs['level']) {
      final int l when l >= 1 && l <= 6 => 'h$l',
      _ => 'h2',
    },
    'bulletList' => 'ul',
    'orderedList' => 'ol',
    'listItem' => 'li',
    'blockquote' => 'blockquote',
    'codeBlock' => 'pre',
    _ => null,
  };
  switch (type) {
    case 'hardBreak':
      out.write('<br>');
      return;
    case 'horizontalRule':
      out.write('<hr>');
      return;
  }
  if (tag != null) out.write('<$tag>');
  final content = node['content'];
  if (content is List) {
    for (final child in content) {
      _node(child, out);
    }
  }
  if (tag != null) out.write('</$tag>');
}

void _text(Map node, StringBuffer out) {
  final text = node['text'];
  if (text is! String || text.isEmpty) return;
  final marks = [
    if (node['marks'] case final List marks)
      for (final m in marks)
        if (m case {'type': final String t}) ?_markTags[t],
  ];
  for (final tag in marks) {
    out.write('<$tag>');
  }
  out.write(_escape(text));
  for (final tag in marks.reversed) {
    out.write('</$tag>');
  }
}

const _markTags = {
  'bold': 'strong',
  'italic': 'em',
  'strike': 's',
  'underline': 'u',
  'code': 'code',
};

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
