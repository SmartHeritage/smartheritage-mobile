import 'package:flutter/material.dart';

/// Mô hình hiện vật (dữ liệu mẫu cho UI).
class Artifact {
  const Artifact({
    required this.id,
    required this.name,
    required this.era,
    required this.zone,
    required this.shortIntro,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.rating,
    required this.reviewCount,
    required this.audioDuration,
    required this.videoDuration,
    this.imageUrl,
    this.imageAsset,
    this.detailImageAsset,
    this.imageAlignment = Alignment.center,
    this.detailImageAlignment = Alignment.center,
    this.mapX = 0.5,
    this.mapY = 0.5,
    this.lat = MockData.siteLat,
    this.lng = MockData.siteLng,
  });

  final String id;
  final String name;
  final String era;
  final String zone;
  final String shortIntro;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final double rating;
  final int reviewCount;
  final String audioDuration;
  final String videoDuration;

  /// Ảnh thật của hiện vật (điền link khi có; null → dùng ảnh placeholder).
  final String? imageUrl;

  /// Ảnh thật đóng gói sẵn trong app (đường dẫn asset). Ưu tiên hơn [imageUrl].
  /// Dùng cho thumbnail và ảnh thường.
  final String? imageAsset;

  /// Ảnh khổ lớn dùng riêng cho phần hero ở trang chi tiết.
  /// Nếu null → dùng tạm [imageAsset].
  final String? detailImageAsset;

  /// Căn khung riêng cho ảnh hero trang chi tiết. y = -1 lấy phần trên.
  final Alignment detailImageAlignment;

  /// Căn khung khi cắt ảnh (BoxFit.cover). y = -1 lấy phần trên, +1 lấy phần dưới.
  final Alignment imageAlignment;

  /// Vị trí tương đối trên bản đồ minh hoạ (0..1). (giữ lại cho tương thích cũ)
  final double mapX;
  final double mapY;

  /// Toạ độ địa lý thật của hiện vật (dùng cho bản đồ OpenStreetMap).
  final double lat;
  final double lng;
}

class VisitRecord {
  const VisitRecord({
    required this.artifact,
    required this.dateLabel,
    required this.timeLabel,
  });

  final Artifact artifact;
  final String dateLabel;
  final String timeLabel;
}

/// Loại thông báo — quyết định icon và màu hiển thị.
enum AppNotificationKind { beacon, artifact, event, feedback }

/// Một thông báo trong danh sách chuông (dữ liệu mẫu, chưa gắn FCM thật).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.artifactId,
  });

  final String id;
  final AppNotificationKind kind;
  final String title;
  final String body;
  final String timeLabel;

  /// Có giá trị thì bấm vào thông báo sẽ mở trang chi tiết hiện vật đó.
  final String? artifactId;
}

class MockData {
  MockData._();

  /// Tâm khu di tích (ví dụ: Hoàng thành Thăng Long, Hà Nội).
  /// Đổi 2 giá trị này sang toạ độ khu di tích thật của bạn khi có.
  static const double siteLat = 21.0354;
  static const double siteLng = 105.8402;

  static const artifacts = <Artifact>[
    Artifact(
      id: 'a1',
      name: 'Trống đồng Đông Sơn',
      era: 'Văn hoá Đông Sơn · TK VII TCN',
      zone: 'Khu trưng bày A',
      shortIntro: 'Biểu tượng rực rỡ của nền văn minh Việt cổ.',
      description:
          'Trống đồng Đông Sơn là hiện vật tiêu biểu nhất của văn hoá Đông Sơn, '
          'phản ánh trình độ đúc đồng điêu luyện của cư dân Việt cổ. Mặt trống '
          'trang trí hoa văn hình mặt trời, chim lạc, thuyền và các sinh hoạt '
          'cộng đồng, thể hiện đời sống tinh thần phong phú và tín ngưỡng thờ '
          'mặt trời của người Việt cổ cách đây hơn 2.000 năm.',
      icon: Icons.album_outlined,
      gradient: [Color(0xFF8C2B21), Color(0xFFC1613C)],
      imageAsset: 'assets/images/trong_dong_dong_son.jpg',
      rating: 4.8,
      reviewCount: 236,
      audioDuration: '03:45',
      videoDuration: '02:10',
      mapX: 0.26,
      mapY: 0.30,
      lat: 21.03565,
      lng: 105.83980,
    ),
    Artifact(
      id: 'a2',
      name: 'Ấn vàng triều Nguyễn',
      era: 'Triều Nguyễn · 1823',
      zone: 'Khu trưng bày B',
      shortIntro: 'Bảo vật tượng trưng cho quyền lực hoàng gia.',
      description:
          'Chiếc ấn vàng được đúc dưới thời vua Minh Mạng, là biểu tượng quyền '
          'lực tối cao của triều đình nhà Nguyễn. Ấn được đúc bằng vàng ròng, '
          'núm hình rồng cuộn tinh xảo, thể hiện đỉnh cao nghệ thuật kim hoàn '
          'cung đình Huế thế kỷ XIX.',
      icon: Icons.workspace_premium_outlined,
      gradient: [Color(0xFFB24435), Color(0xFFE7C08A)],
      imageAsset: 'assets/images/an_vang_trieu_nguyen.jpg',
      // Xích khung lên trên để thấy con rồng (phần trên ảnh) nhiều hơn.
      imageAlignment: Alignment(0, -0.6),
      rating: 4.7,
      reviewCount: 189,
      audioDuration: '04:20',
      videoDuration: '03:05',
      mapX: 0.62,
      mapY: 0.22,
      lat: 21.03595,
      lng: 105.84045,
    ),
    Artifact(
      id: 'a3',
      name: 'Tượng Phật A Di Đà',
      era: 'Thời Lý · TK XI',
      zone: 'Khu trưng bày A',
      shortIntro: 'Kiệt tác điêu khắc đá thời Lý.',
      description:
          'Pho tượng Phật A Di Đà chùa Phật Tích là kiệt tác điêu khắc đá thời '
          'Lý, thể hiện sự kết hợp hài hoà giữa nghệ thuật Phật giáo và bản sắc '
          'dân tộc. Đường nét mềm mại, cân đối của pho tượng đạt đến trình độ '
          'thẩm mỹ mẫu mực trong lịch sử mỹ thuật Việt Nam.',
      icon: Icons.self_improvement_outlined,
      gradient: [Color(0xFF5E1A13), Color(0xFFB24435)],
      imageAsset: 'assets/images/tuong_phat_a_di_da.jpg',
      // Xích nhẹ lên trên để thấy tượng Phật (phần trên) rõ hơn.
      imageAlignment: Alignment(0, -0.3),
      rating: 4.9,
      reviewCount: 312,
      audioDuration: '05:10',
      videoDuration: '04:00',
      mapX: 0.35,
      mapY: 0.62,
      lat: 21.03510,
      lng: 105.83955,
    ),
    Artifact(
      id: 'a4',
      name: 'Gốm hoa nâu thời Trần',
      era: 'Thời Trần · TK XIII',
      zone: 'Khu trưng bày C',
      shortIntro: 'Dòng gốm đặc sắc thuần Việt.',
      description:
          'Gốm hoa nâu là dòng gốm đặc trưng của thời Trần với kỹ thuật khắc '
          'chìm tô nâu độc đáo. Hoa văn trang trí thường là hoa sen, hoa cúc và '
          'các đề tài dân gian gần gũi, phản ánh tinh thần phóng khoáng, khoẻ '
          'khoắn của nghệ thuật Đại Việt.',
      icon: Icons.emoji_food_beverage_outlined,
      gradient: [Color(0xFFA8481F), Color(0xFFD99A4E)],
      imageAsset: 'assets/images/gom_hoa_nau.jpg',
      rating: 4.5,
      reviewCount: 98,
      audioDuration: '02:55',
      videoDuration: '01:45',
      mapX: 0.74,
      mapY: 0.55,
      lat: 21.03540,
      lng: 105.84075,
    ),
    Artifact(
      id: 'a5',
      name: 'Súng thần công',
      era: 'Triều Nguyễn · TK XIX',
      zone: 'Sân ngoài trời',
      shortIntro: 'Chứng tích một thời binh lửa.',
      description:
          'Khẩu súng thần công bằng đồng được đúc dưới triều Nguyễn, từng được '
          'bố trí phòng thủ tại kinh thành. Thân súng chạm khắc hoa văn và minh '
          'văn ghi rõ niên đại, trọng lượng, là tư liệu quý về kỹ thuật quân sự '
          'và nghệ thuật đúc đồng thế kỷ XIX.',
      icon: Icons.security_outlined,
      gradient: [Color(0xFF8C2B21), Color(0xFFD98E5A)],
      imageAsset: 'assets/images/sung_than_cong.jpg',
      // Xích nhẹ xuống để tập trung vào khẩu súng, bớt phần trần/mô hình phía trên.
      imageAlignment: Alignment(0, 0.2),
      rating: 4.3,
      reviewCount: 74,
      audioDuration: '03:15',
      videoDuration: '02:30',
      mapX: 0.52,
      mapY: 0.80,
      lat: 21.03470,
      lng: 105.84010,
    ),
  ];

  static Artifact byId(String id) =>
      artifacts.firstWhere((a) => a.id == id, orElse: () => artifacts.first);

  static final visitHistory = <VisitRecord>[
    VisitRecord(
      artifact: artifacts[0],
      dateLabel: 'Hôm nay',
      timeLabel: '09:45',
    ),
    VisitRecord(
      artifact: artifacts[2],
      dateLabel: 'Hôm nay',
      timeLabel: '09:20',
    ),
    VisitRecord(
      artifact: artifacts[1],
      dateLabel: '15/07/2026',
      timeLabel: '15:30',
    ),
    VisitRecord(
      artifact: artifacts[3],
      dateLabel: '15/07/2026',
      timeLabel: '14:50',
    ),
    VisitRecord(
      artifact: artifacts[4],
      dateLabel: '02/07/2026',
      timeLabel: '10:05',
    ),
  ];

  static const notifications = <AppNotification>[
    AppNotification(
      id: 'n1',
      kind: AppNotificationKind.beacon,
      title: 'Bạn đang ở gần Ấn vàng triều Nguyễn',
      body: 'iBeacon phát hiện bạn ở Khu trưng bày B. Mở thuyết minh để nghe '
          'giới thiệu về bảo vật này.',
      timeLabel: '5 phút trước',
      artifactId: 'a2',
    ),
    AppNotification(
      id: 'n2',
      kind: AppNotificationKind.artifact,
      title: 'Hiện vật mới được bổ sung',
      body: 'Trống đồng Đông Sơn vừa có thêm bản thuyết minh tiếng Anh và '
          '6 ảnh chi tiết mới.',
      timeLabel: '2 giờ trước',
      artifactId: 'a1',
    ),
    AppNotification(
      id: 'n3',
      kind: AppNotificationKind.event,
      title: 'Triển lãm chuyên đề cuối tuần',
      body: '"Gốm Việt qua các triều đại" mở tại Khu trưng bày C, 8h–17h thứ '
          'Bảy và Chủ nhật này.',
      timeLabel: 'Hôm qua',
    ),
    AppNotification(
      id: 'n4',
      kind: AppNotificationKind.feedback,
      title: 'Cảm ơn phản hồi của bạn',
      body: 'Ban quản lý đã tiếp nhận góp ý về chất lượng âm thanh và đang '
          'cải thiện.',
      timeLabel: '15/07/2026',
    ),
    AppNotification(
      id: 'n5',
      kind: AppNotificationKind.event,
      title: 'Giờ mở cửa dịp lễ',
      body: 'Khu di tích mở cửa tới 21h trong ba ngày lễ, có tour đêm kèm '
          'thuyết minh trực tiếp.',
      timeLabel: '12/07/2026',
    ),
  ];
}

/// Trạng thái yêu thích dùng chung cho toàn app (UI demo, chưa có backend).
class FavoriteStore {
  FavoriteStore._();

  static final ValueNotifier<Set<String>> ids =
      ValueNotifier<Set<String>>({'a1', 'a3'});

  static bool isFavorite(String id) => ids.value.contains(id);

  static void toggle(String id) {
    final next = Set<String>.from(ids.value);
    if (!next.remove(id)) next.add(id);
    ids.value = next;
  }
}
