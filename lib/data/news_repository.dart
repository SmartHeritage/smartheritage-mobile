import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import 'mock_data.dart';
import 'tiptap.dart';

/// Một bài viết (tin tức) do ban quản lý đăng ở trang admin, mục Bài viết.
///
/// Danh sách (`GET /blogs`) chỉ có tiêu đề, ngày, ảnh đại diện — không có tóm
/// tắt hay nội dung. Nội dung lấy riêng khi mở bài ([NewsRepository.fetchBody]).
class NewsItem {
  const NewsItem({
    required this.id,
    required this.slug,
    required this.title,
    this.publishedAt,
    this.imageUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: json['id'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    title: (json['title'] as String? ?? '').trim(),
    publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    // URL tuyệt đối theo PUBLIC_BASE_URL (có thể là localhost) — đổi host như
    // ảnh hiện vật.
    imageUrl: Artifact.resolveMediaUrl(json['featuredImageUrl'] as String?),
  );

  final String id;

  /// Đường dẫn của bài trên backend (`GET /blogs/:slug`). Admin đổi tiêu đề
  /// thì slug có thể đổi; slug cũ được backend chuyển hướng 301 sang slug mới.
  final String slug;
  final String title;
  final DateTime? publishedAt;

  /// Ảnh đại diện; `null` thì thẻ/trang chi tiết vẽ nền thay thế.
  final String? imageUrl;

  /// Ngày đăng kiểu `24/09/2026`, theo giờ máy. Rỗng nếu backend không trả.
  String get dateLabel {
    final d = publishedAt?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

/// Tin tức trên trang chủ, lấy từ bài viết đã xuất bản của backend.
///
/// Không có dữ liệu mẫu: tin giả trông như thật dễ làm khách hiểu nhầm, nên
/// chưa có bài (hoặc không tải được) thì trang chủ ẩn hẳn mục Tin tức.
class NewsRepository extends ChangeNotifier {
  NewsRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static NewsRepository _instance = NewsRepository();

  static NewsRepository get instance => _instance;

  /// Thay kho dùng chung bằng bản chạy trên ApiClient giả cho widget test.
  @visibleForTesting
  static set instance(NewsRepository repository) => _instance = repository;

  final ApiClient _api;

  /// Số bài hiện ở carousel trang chủ.
  static const _limit = 10;

  /// Backend bắt buộc `?lang=` và không tự rơi về thứ tiếng khác; mã không có
  /// trong Language Registry thì 400 → thử lại bằng tiếng Việt.
  static const _fallbackLanguage = 'vi';

  /// Ngôn ngữ khách chọn — `LanguageController` gắn vào, giống
  /// `ArtifactRepository.language`. Đổi xong phải [refresh].
  String? language;

  List<NewsItem> _items = const [];
  bool _isLoading = false;
  bool _loadedOnce = false;

  List<NewsItem> get items => _items;
  bool get isLoading => _isLoading;

  /// Nạp sẵn danh sách cho widget test, không đụng mạng.
  @visibleForTesting
  void setItemsForTest(List<NewsItem> items) {
    _items = items;
    _loadedOnce = true;
    notifyListeners();
  }

  /// Tải lần đầu; gọi lại nhiều lần không tốn thêm request.
  Future<void> ensureLoaded() async {
    if (_loadedOnce || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _getWithLanguage(
        '/blogs',
        (lang) => {'lang': lang, 'limit': '$_limit'},
      );
      final raw = data is Map<String, dynamic> ? data['items'] : null;
      _items = [
        if (raw is List)
          for (final j in raw.whereType<Map<String, dynamic>>())
            if (NewsItem.fromJson(j) case final item
                when item.slug.isNotEmpty && item.title.isNotEmpty)
              item,
      ];
      _loadedOnce = true;
    } on ApiException {
      // Giữ danh sách đang có: một lần gọi hỏng không đáng xoá tin đã hiện.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nội dung bài dạng HTML cho `RichTextContent`. Bài đã bị gỡ/huỷ xuất bản
  /// thì backend trả 404 → [ApiException].
  Future<String> fetchBody(NewsItem item) async {
    final data = await _getWithLanguage(
      '/blogs/${Uri.encodeComponent(item.slug)}',
      (lang) => {'lang': lang},
    );
    if (data is! Map<String, dynamic>) {
      throw ApiException(appStrings.invalidServerData);
    }
    return tiptapToHtml(data['contentJson']);
  }

  Future<dynamic> _getWithLanguage(
    String path,
    Map<String, String> Function(String lang) query,
  ) async {
    final lang = language ?? _fallbackLanguage;
    try {
      return await _api.get(path, query: query(lang));
    } on ApiException catch (e) {
      if (e.statusCode != 400 || lang == _fallbackLanguage) rethrow;
      return _api.get(path, query: query(_fallbackLanguage));
    }
  }
}
