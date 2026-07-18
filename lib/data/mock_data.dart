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
    this.mapX = 0.5,
    this.mapY = 0.5,
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

  /// Vị trí tương đối trên bản đồ minh hoạ (0..1).
  final double mapX;
  final double mapY;
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

class MockData {
  MockData._();

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
      gradient: [Color(0xFF1B4332), Color(0xFF40916C)],
      rating: 4.8,
      reviewCount: 236,
      audioDuration: '03:45',
      videoDuration: '02:10',
      mapX: 0.26,
      mapY: 0.30,
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
      gradient: [Color(0xFF2D6A4F), Color(0xFF74C69D)],
      rating: 4.7,
      reviewCount: 189,
      audioDuration: '04:20',
      videoDuration: '03:05',
      mapX: 0.62,
      mapY: 0.22,
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
      gradient: [Color(0xFF081C15), Color(0xFF2D6A4F)],
      rating: 4.9,
      reviewCount: 312,
      audioDuration: '05:10',
      videoDuration: '04:00',
      mapX: 0.35,
      mapY: 0.62,
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
      gradient: [Color(0xFF40916C), Color(0xFF95D5B2)],
      rating: 4.5,
      reviewCount: 98,
      audioDuration: '02:55',
      videoDuration: '01:45',
      mapX: 0.74,
      mapY: 0.55,
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
      gradient: [Color(0xFF1B4332), Color(0xFF52B788)],
      rating: 4.3,
      reviewCount: 74,
      audioDuration: '03:15',
      videoDuration: '02:30',
      mapX: 0.52,
      mapY: 0.80,
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
