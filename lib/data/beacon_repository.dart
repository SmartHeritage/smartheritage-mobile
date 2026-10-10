import '../services/api_client.dart';
import '../services/device_id.dart';

/// Định danh một iBeacon nghe được qua sóng BLE.
class BeaconIdentity {
  const BeaconIdentity({
    required this.proximityUuid,
    required this.major,
    required this.minor,
  });

  final String proximityUuid;
  final int major;
  final int minor;

  Map<String, dynamic> toJson() =>
      {'proximityUuid': proximityUuid, 'major': major, 'minor': minor};

  @override
  bool operator ==(Object other) =>
      other is BeaconIdentity &&
      other.proximityUuid.toLowerCase() == proximityUuid.toLowerCase() &&
      other.major == major &&
      other.minor == minor;

  @override
  int get hashCode => Object.hash(proximityUuid.toLowerCase(), major, minor);
}

/// Một kết quả của `POST /beacons/resolve`: beacon đó (nếu backend biết) đang
/// phục vụ những hiện vật nào. Một beacon có thể phục vụ 0, 1 hoặc nhiều hiện
/// vật — backend không chọn hộ, việc chọn là của app.
class BeaconCandidate {
  const BeaconCandidate({
    required this.identity,
    required this.resolved,
    this.beaconId,
    this.name,
    this.artifactIds = const [],
  });

  factory BeaconCandidate.fromJson(Map<String, dynamic> json) =>
      BeaconCandidate(
        identity: BeaconIdentity(
          proximityUuid: (json['proximityUuid'] as String?) ?? '',
          major: (json['major'] as num?)?.toInt() ?? 0,
          minor: (json['minor'] as num?)?.toInt() ?? 0,
        ),
        resolved: json['resolved'] == true,
        beaconId: json['beaconId'] as String?,
        name: json['name'] as String?,
        artifactIds: (json['artifactIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );

  final BeaconIdentity identity;
  final bool resolved;
  final String? beaconId;
  final String? name;
  final List<String> artifactIds;
}

/// Gọi các endpoint beacon public của smartheritage-BE.
class BeaconRepository {
  BeaconRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static BeaconRepository instance = BeaconRepository();

  final ApiClient _api;

  /// Hỏi backend các beacon vừa nghe được đang phục vụ hiện vật nào. Thứ tự
  /// kết quả giữ đúng thứ tự gửi lên; beacon lạ trả `resolved: false` chứ
  /// không làm hỏng cả lô.
  Future<List<BeaconCandidate>> resolve(List<BeaconIdentity> heard) async {
    if (heard.isEmpty) return const [];
    final data = await _api.post('/beacons/resolve', body: {
      // Backend giới hạn 50 beacon một lần.
      'beacons': heard.take(50).map((b) => b.toJson()).toList(),
    });
    final raw = data is Map ? data['candidates'] : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BeaconCandidate.fromJson)
        .toList();
  }

  /// Ghi một lượt quét (`POST /scans`): backend đếm lượt khách, cập nhật mức
  /// đông người, và — nếu đang đăng nhập — ghi lịch sử tham quan. Gửi kèm
  /// [artifactId] khi beacon phục vụ nhiều hiện vật, để lượt ghé được tính
  /// đúng cho hiện vật khách đang xem.
  ///
  /// [source] là `manual` khi lượt quét đến từ bộ quét giả, để số liệu demo
  /// không lẫn với lượt quét beacon thật trên dashboard.
  Future<void> recordScan(
    BeaconIdentity beacon, {
    String? artifactId,
    String source = 'beacon',
  }) async {
    await _api.post('/scans', body: {
      ...beacon.toJson(),
      'deviceId': await DeviceId.get(),
      'source': source,
      'artifactId': ?artifactId,
    });
  }
}
