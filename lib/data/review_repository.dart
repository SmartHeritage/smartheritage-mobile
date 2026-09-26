import '../services/api_client.dart';

/// Mã tag backend nhận (`REVIEW_TAGS`) kèm nhãn hiển thị.
///
/// Thứ tự giữ đúng như bên backend để hai đầu đọc cùng một danh sách. Gửi mã
/// chứ không gửi nhãn: nhãn là tiếng Việt, đổi chữ một cái là thống kê bên
/// admin gãy.
const reviewTagLabels = <String, String>{
  'content_good': 'Nội dung hấp dẫn',
  'narration_clear': 'Thuyết minh rõ ràng',
  'wayfinding_easy': 'Dễ tìm vị trí',
  'images_good': 'Hình ảnh đẹp',
  'languages_missing': 'Cần thêm ngôn ngữ',
  'audio_poor': 'Âm thanh chưa tốt',
};

/// Một đánh giá đã được duyệt, từ `GET /reviews`.
class Review {
  const Review({
    required this.id,
    required this.rating,
    this.tags = const [],
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] as String?) ?? '',
        rating: switch (json['rating']) {
          num n => n.toInt(),
          String s => int.tryParse(s) ?? 0,
          _ => 0,
        },
        tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
        comment: json['comment'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      );

  final String id;
  final int rating;
  final List<String> tags;
  final String? comment;
  final DateTime? createdAt;

  /// Nhãn tiếng Việt của các tag; bỏ qua mã lạ để backend thêm tag mới không
  /// làm vỡ màn hình.
  List<String> get tagLabels =>
      tags.map((t) => reviewTagLabels[t]).whereType<String>().toList();
}

/// Đọc và gửi đánh giá.
///
/// Không giữ state: danh sách đánh giá gắn với từng hiện vật và chỉ dùng ở
/// một tab, nên màn hình tự nạp rồi tự giữ.
class ReviewRepository {
  ReviewRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static ReviewRepository instance = ReviewRepository();

  final ApiClient _api;

  /// `GET /reviews` yêu cầu artifactId là UUID. Khi đang chạy trên dữ liệu
  /// mock (id 'a1'..'a5') thì gọi lên sẽ ăn 400 — chặn trước cho sạch.
  static bool isServerId(String id) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(id);

  Future<List<Review>> listForArtifact(String artifactId) async {
    if (!isServerId(artifactId)) return const [];
    final data = await _api.get('/reviews', query: {'artifactId': artifactId});
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(Review.fromJson).toList();
  }

  /// Gửi đánh giá. [artifactId] để trống nghĩa là góp ý chung cho khu di tích
  /// — backend cho phép, và đó là cách màn hình phản hồi mở từ trang cá nhân
  /// hoạt động.
  Future<void> submit({
    String? artifactId,
    required int rating,
    List<String> tags = const [],
    String? comment,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (artifactId != null && isServerId(artifactId)) {
      body['artifactId'] = artifactId;
    }
    if (tags.isNotEmpty) body['tags'] = tags;
    final text = comment?.trim();
    if (text != null && text.isNotEmpty) body['comment'] = text;

    await _api.post('/reviews', body: body);
  }
}
