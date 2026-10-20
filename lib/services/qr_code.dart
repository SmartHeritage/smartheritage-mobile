/// Đọc id hiện vật từ nội dung mã QR.
///
/// Backend/admin chưa có quy ước mã QR (2026-10-19), nên app nhận mọi dạng
/// hợp lý chứa id hiện vật:
/// - id trần (`3f2a…-…`);
/// - link có đoạn `/artifacts/<id>` (vd. link trang hiện vật, deep link
///   `smartheritage://artifacts/<id>`);
/// - link có query `artifactId=<id>` hoặc `id=<id>`.
///
/// Trả các ứng viên theo thứ tự ưu tiên; màn quét tra lần lượt trong danh mục
/// hiện vật, nên chuỗi lạ chỉ đơn giản là không khớp gì.
List<String> artifactIdCandidates(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];
  final candidates = <String>[];
  void add(String? id) {
    final value = id?.trim();
    if (value != null && value.isNotEmpty && !candidates.contains(value)) {
      candidates.add(value);
    }
  }

  final uri = Uri.tryParse(text);
  if (uri != null && (uri.hasScheme || text.contains('/'))) {
    // `smartheritage://artifacts/<id>`: "artifacts" là host chứ không nằm
    // trong path.
    final segments = [if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
    final i = segments.indexOf('artifacts');
    if (i >= 0 && i + 1 < segments.length) add(segments[i + 1]);
    add(uri.queryParameters['artifactId']);
    add(uri.queryParameters['id']);
    for (final m in _uuid.allMatches(text)) {
      add(m.group(0));
    }
  }
  add(text);
  return candidates;
}

final _uuid = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);
