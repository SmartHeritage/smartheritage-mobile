import 'mock_data.dart';

/// Khu du lịch (`GET /tourism-areas`) — cấp 1 của bản đồ, chứa các điểm tham
/// quan. Toạ độ do admin ghim trong CRM, có thể chưa có.
class TourismArea {
  const TourismArea({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    this.description,
    this.address,
    this.imageUrl,
  });

  factory TourismArea.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    final pinned = lat != null && lng != null;
    return TourismArea(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      lat: pinned ? lat : null,
      lng: pinned ? lng : null,
      description: _text(json['description']),
      address: _text(json['address']),
      // Ảnh bìa admin tải lên — URL tuyệt đối theo PUBLIC_BASE_URL của backend.
      imageUrl: Artifact.resolveMediaUrl(json['imageUrl'] as String?),
    );
  }

  /// Chuỗi rỗng/toàn khoảng trắng coi như chưa nhập.
  static String? _text(Object? raw) {
    final text = (raw as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final String? description;
  final String? address;
  final String? imageUrl;

  bool get isPinned => lat != null && lng != null;
}

/// Beacon trên bản đồ (phần `beacons` của `GET /attractions/:id/map`).
/// Toạ độ là vị trí của chính thiết bị — có thể chưa được đặt.
class MapBeacon {
  const MapBeacon({
    required this.id,
    required this.name,
    this.attractionId,
    this.lat,
    this.lng,
  });

  factory MapBeacon.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    final pinned = lat != null && lng != null;
    return MapBeacon(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Beacon',
      attractionId: json['attractionId'] as String?,
      lat: pinned ? lat : null,
      lng: pinned ? lng : null,
    );
  }

  final String id;
  final String name;
  final String? attractionId;
  final double? lat;
  final double? lng;

  bool get isPinned => lat != null && lng != null;
}

/// Điểm tham quan (`GET /attractions`) — nhóm hiện vật thay cho Zone cũ.
class Attraction {
  const Attraction({
    required this.id,
    required this.name,
    this.tourismAreaId,
    this.isIndoor = false,
    this.floorPlanUrl,
    this.floorId,
    this.planBlock,
    this.mapBlock,
  });

  factory Attraction.fromJson(Map<String, dynamic> json) => Attraction(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        tourismAreaId: json['tourismAreaId'] as String?,
        isIndoor: json['mapType'] == 'INDOOR',
        floorPlanUrl: Artifact.resolveMediaUrl(json['floorPlanUrl'] as String?),
        floorId: json['floorId'] as String?,
        planBlock: _ring(json['areaMapBoundary']),
        mapBlock: _ring(json['boundary']),
      );

  final String id;
  final String name;
  final String? tourismAreaId;

  /// `INDOOR` thì vị trí hiện vật/beacon nằm trên sơ đồ tầng ([floorPlanUrl]),
  /// tính theo tỉ lệ 0..1 (`mapX`/`mapY`), chứ không phải toạ độ GPS.
  final bool isIndoor;
  final String? floorPlanUrl;

  /// Tầng của khu du lịch mà khu vực nằm trên; `null` = không thuộc tầng nào.
  final String? floorId;

  /// Khối admin vẽ trên **sơ đồ tầng** (`areaMapBoundary`): các đỉnh (x, y)
  /// theo tỉ lệ 0..1 từ góc trên trái ảnh, như mapX/mapY.
  final List<(double, double)>? planBlock;

  /// Khối admin vẽ trên **bản đồ thật** (`boundary`): các đỉnh (lng, lat) —
  /// dùng cho tầng không có ảnh sơ đồ (vd. tầng trệt ngoài trời).
  final List<(double, double)>? mapBlock;

  bool get hasFloorPlan => isIndoor && floorPlanUrl != null;

  /// Vòng ngoài của GeoJSON Polygon, bỏ đỉnh cuối lặp lại đỉnh đầu.
  static List<(double, double)>? _ring(Object? geo) {
    if (geo is! Map || geo['type'] != 'Polygon') return null;
    final rings = geo['coordinates'];
    if (rings is! List || rings.isEmpty || rings.first is! List) return null;
    final points = <(double, double)>[
      for (final p in rings.first as List)
        if (p is List && p.length >= 2 && p[0] is num && p[1] is num)
          ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    if (points.length > 1 && points.first == points.last) points.removeLast();
    return points.length >= 3 ? points : null;
  }
}

/// Tầng của một khu du lịch (`GET /tourism-areas/:id/floors`).
///
/// Có [floorPlanUrl] thì khu vực trên tầng là khối vẽ trên ảnh sơ đồ
/// ([Attraction.planBlock]); không có thì khối vẽ trên bản đồ thật
/// ([Attraction.mapBlock]).
class Floor {
  const Floor({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.floorPlanUrl,
  });

  factory Floor.fromJson(Map<String, dynamic> json) => Floor(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        floorPlanUrl: Artifact.resolveMediaUrl(json['floorPlanUrl'] as String?),
      );

  final String id;
  final String name;

  /// Thứ tự admin xếp ở trang Khu vực — app giữ đúng thứ tự đó.
  final int sortOrder;
  final String? floorPlanUrl;
}

/// Một điểm đặt trên sơ đồ tầng, theo tỉ lệ 0..1 của ảnh (không phải pixel).
class FloorPlanMarker {
  const FloorPlanMarker({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.artifact,
  });

  final String id;
  final String name;
  final double x;
  final double y;

  /// Có giá trị thì đây là hiện vật (bấm vào mở chi tiết); `null` là beacon.
  final Artifact? artifact;

  bool get isBeacon => artifact == null;
}

/// `GET /attractions/:id/map`: cấu hình bản đồ của điểm tham quan cùng các
/// beacon và hiện vật PUBLISHED thuộc về nó.
class AttractionMap {
  const AttractionMap({
    required this.attraction,
    required this.markers,
    this.beacons = const [],
  });

  factory AttractionMap.fromJson(
    Map<String, dynamic> json, {
    Artifact? Function(String id)? lookup,
  }) {
    double? d(Object? v) => (v as num?)?.toDouble();
    final markers = <FloorPlanMarker>[];
    for (final b in (json['beacons'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()) {
      final x = d(b['mapX']), y = d(b['mapY']);
      if (x == null || y == null) continue;
      markers.add(FloorPlanMarker(
        id: b['id'] as String? ?? '',
        name: b['name'] as String? ?? 'Beacon',
        x: x,
        y: y,
      ));
    }
    for (final a in (json['artifacts'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()) {
      final x = d(a['mapX']), y = d(a['mapY']);
      final id = a['id'] as String?;
      if (x == null || y == null || id == null) continue;
      final artifact = lookup?.call(id) ?? Artifact.fromJson(a);
      markers.add(FloorPlanMarker(
        id: id,
        name: artifact.name,
        x: x,
        y: y,
        artifact: artifact,
      ));
    }
    return AttractionMap(
      attraction: Attraction.fromJson(
          (json['attraction'] as Map?)?.cast<String, dynamic>() ?? const {}),
      markers: markers,
      beacons: [
        for (final b in (json['beacons'] as List? ?? const [])
            .whereType<Map<String, dynamic>>())
          MapBeacon.fromJson(b),
      ],
    );
  }

  final Attraction attraction;

  /// Ghim trên sơ đồ tầng (chỉ những thứ đã có `mapX`/`mapY`).
  final List<FloorPlanMarker> markers;

  /// Mọi beacon của điểm tham quan, kèm toạ độ địa lý nếu có.
  final List<MapBeacon> beacons;
}
