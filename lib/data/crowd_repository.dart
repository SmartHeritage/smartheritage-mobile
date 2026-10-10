import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

/// Mức đông người quanh một hiện vật, ước lượng từ số máy đang ở trong vùng
/// beacon (backend tính "đang có mặt" trong 5 phút gần nhất). Đây là số
/// **thiết bị**, không phải số người — giao diện phải nói "khoảng".
class CrowdInfo {
  const CrowdInfo({
    required this.activeDevices,
    required this.isSharedZone,
    this.beaconName,
  });

  final int activeDevices;

  /// `true` khi beacon phục vụ nhiều hiện vật: con số là của cả khu vực beacon
  /// đó, không chia riêng được cho từng hiện vật.
  final bool isSharedZone;
  final String? beaconName;

  String get label {
    if (activeDevices == 0) return 'Đang vắng khách';
    final where = isSharedZone && beaconName != null
        ? 'quanh khu vực $beaconName'
        : 'đang ở đây';
    return '~$activeDevices khách $where';
  }
}

/// Đọc `GET /crowd/beacons` — public, chỉ đọc.
class CrowdRepository extends ChangeNotifier {
  CrowdRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final CrowdRepository instance = CrowdRepository();

  final ApiClient _api;

  Map<String, CrowdInfo> _byArtifact = const {};
  Map<String, CrowdInfo> _byBeacon = const {};

  CrowdInfo? forArtifact(String artifactId) => _byArtifact[artifactId];

  /// Mức đông người của cả vùng phủ sóng một beacon.
  CrowdInfo? forBeacon(String beaconId) => _byBeacon[beaconId];

  /// Lỗi thì giữ số cũ — mức đông người là thông tin phụ, không đáng báo lỗi.
  Future<void> refresh({String? attractionId}) async {
    try {
      final data = await _api.get(
        '/crowd/beacons',
        query: attractionId == null ? null : {'attractionId': attractionId},
      );
      if (data is! List) return;
      final next = <String, CrowdInfo>{};
      final byBeacon = <String, CrowdInfo>{};
      for (final b in data.whereType<Map<String, dynamic>>()) {
        final count = (b['activeDeviceCount'] as num?)?.toInt() ?? 0;
        final name = b['beaconName'] as String?;
        if (b['beaconId'] case final String id) {
          byBeacon[id] = CrowdInfo(
            activeDevices: count,
            isSharedZone: true,
            beaconName: name,
          );
        }
        if (b['observationType'] == 'ARTIFACT' && b['artifactId'] is String) {
          next[b['artifactId'] as String] = CrowdInfo(
            activeDevices: count,
            isSharedZone: false,
            beaconName: name,
          );
          continue;
        }
        final ids = (b['artifactIds'] as List?)?.whereType<String>() ?? [];
        for (final id in ids) {
          next[id] = CrowdInfo(
            activeDevices: count,
            isSharedZone: true,
            beaconName: name,
          );
        }
      }
      _byArtifact = next;
      _byBeacon = byBeacon;
      notifyListeners();
    } on ApiException {
      // giữ nguyên
    }
  }
}
