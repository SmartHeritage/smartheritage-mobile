import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/artifact_repository.dart';
import '../data/beacon_repository.dart';
import '../data/mock_data.dart';
import '../services/ibeacon_scanner.dart';

/// Trạng thái quét iBeacon dùng chung toàn app.
///
/// Trên iPhone/Android thật, tín hiệu đến từ Bluetooth ([IBeaconScanner]):
/// beacon nghe được → `POST /beacons/resolve` để biết beacon phục vụ hiện vật
/// nào → chọn beacon gần nhất → `POST /scans` để ghi lượt ghé, cập nhật mức
/// đông người và lịch sử tham quan.
///
/// Bộ quét giả vẫn còn cho simulator, cho `flutter test`, và khi build với
/// `--dart-define=BEACON_MOCK=true` để trình diễn không cần beacon.
///
/// Tách khỏi màn hình trang chủ để sidebar bật/tắt được cùng một trạng thái —
/// card trên trang chủ và công tắc trong sidebar luôn khớp nhau.
class BeaconScanController extends ChangeNotifier {
  BeaconScanController._();

  static final BeaconScanController instance = BeaconScanController._();

  /// Beacon bắt được khách sau vài giây kể từ lúc bật quét.
  static const Duration _firstSighting = Duration(seconds: 4);

  /// Beacon thật bắn tín hiệu đều đặn suốt thời gian khách còn đứng trong vùng
  /// sóng, nên mock cũng lặp — có vậy phần chống báo trùng mới được chạy thật.
  static const Duration _rangingInterval = Duration(seconds: 2);

  /// Đứt tín hiệu lâu hơn chừng này thì coi như khách đã rời khỏi hiện vật.
  /// Để rộng tay vì sóng BLE chập chờn: người vẫn đứng yên mà mất vài nhịp
  /// ranging là chuyện thường.
  static const Duration awayThreshold = Duration(seconds: 60);

  /// Còn đứng trong vùng beacon thì cứ chừng này lại báo backend một lần — đủ
  /// dày để máy không rơi khỏi cửa sổ "đang có mặt" 5 phút của mức đông người,
  /// mà không dội một request theo mỗi nhịp ranging 2 giây.
  static const Duration presenceInterval = Duration(seconds: 60);

  /// Rời đi rồi quay lại vẫn phải cách lần báo trước chừng này mới báo tiếp.
  /// Chặn khách đứng ngay ranh giới vùng sóng: tín hiệu vào/ra liên tục thì
  /// riêng [awayThreshold] không đủ để im.
  static const Duration repeatCooldown = Duration(minutes: 5);

  /// Bản V2 cho khách tự chọn khi một beacon phục vụ nhiều hiện vật; V1 giữ
  /// cách cũ (app tự chọn hiện vật có thuyết minh rồi phát luôn). Gán được
  /// trong test vì `flutter test` không build với HOME_V2.
  @visibleForTesting
  static bool askToChoose = const bool.fromEnvironment('HOME_V2');

  bool _isScanning = false;
  Artifact? _detected;
  List<Artifact> _detectedChoices = const [];

  /// Nguồn của lượt quét gần nhất (`beacon`/`manual`) — lượt ghi lại khi khách
  /// chọn hiện vật phải cùng nguồn với lượt ghé.
  String _lastSource = 'beacon';
  Timer? _timer;

  /// Bộ quét Bluetooth đang chạy; `null` khi tắt hoặc đang dùng bộ quét giả.
  BeaconSource? _source;
  BeaconSource? _sourceOverride;

  /// Lỗi lần bật quét gần nhất (thiếu quyền, Bluetooth tắt…), để giao diện báo.
  String? _startError;

  /// Kết quả resolve của từng beacon đã nghe trong phiên quét — hỏi backend
  /// một lần cho mỗi beacon, không phải mỗi nhịp ranging (khoảng 1 giây).
  final Map<BeaconIdentity, BeaconCandidate> _resolved = {};
  final Set<BeaconIdentity> _resolving = {};

  /// Resolve hỏng (mất mạng) thì nghỉ một lúc mới hỏi lại, tránh dội backend
  /// mỗi giây.
  DateTime? _resolveRetryAt;
  static const Duration _resolveBackoff = Duration(seconds: 15);

  /// Lần gần nhất bắt được tín hiệu của từng hiện vật — dùng để biết khách còn
  /// đứng đó hay đã đi chỗ khác.
  final Map<String, DateTime> _lastSeenAt = {};

  /// Lần gần nhất đã bật sheet cho từng hiện vật.
  final Map<String, DateTime> _announcedAt = {};

  /// Lần gần nhất đã gửi `POST /scans` cho từng hiện vật.
  final Map<String, DateTime> _scannedAt = {};

  /// Beacon gần nhất bắt được tín hiệu (đã resolve qua backend) và lúc bắt.
  BeaconCandidate? _zone;
  DateTime? _zoneSeenAt;

  /// Kết quả resolve beacon của phiên quét hiện tại — hỏi backend một lần mỗi
  /// lần bật quét, không phải mỗi nhịp ranging.
  Future<_Sighting?>? _session;

  DateTime Function() _clock = DateTime.now;

  bool get isScanning => _isScanning;

  /// Lỗi lần bật quét gần nhất, `null` nếu đang quét bình thường.
  String? get startError => _startError;

  /// Dùng Bluetooth thật trừ khi đang ở simulator/test hoặc bật BEACON_MOCK.
  bool get _useRealScanner =>
      _sourceOverride != null ||
      (!AppConfig.useMockBeacons && IBeaconScanner.isSupported);

  /// Hiện vật beacon vừa phát hiện, đang chờ màn hình mở sheet giới thiệu.
  /// Bên hiển thị phải gọi [consumeDetection] sau khi xử lý.
  Artifact? get detected => _detected;

  /// Các hiện vật của beacon vừa phát hiện khi beacon đó phục vụ từ hai hiện
  /// vật trở lên (chỉ bản V2) — khách chọn trước, app không tự phát. Rỗng thì
  /// cứ theo [detected] như cũ. Xoá cùng [consumeDetection].
  List<Artifact> get detectedChoices => _detectedChoices;

  /// Vùng beacon khách đang đứng — để bản đồ tô sáng "Bạn đang ở khu vực
  /// Beacon …". Backend không định vị người dùng, nên đây là toàn bộ những gì
  /// app biết về vị trí: tên beacon và các hiện vật nó phục vụ. Mất tín hiệu
  /// quá [awayThreshold] thì coi như đã rời vùng.
  BeaconCandidate? get currentZone {
    final zone = _zone, seenAt = _zoneSeenAt;
    if (zone == null || seenAt == null) return null;
    return _clock().difference(seenAt) < awayThreshold ? zone : null;
  }

  /// Bật quét. Trả về thông báo lỗi để hiện cho khách (thiếu quyền, Bluetooth
  /// tắt…), hoặc `null` khi đã bắt đầu quét.
  Future<String?> startScan() async {
    if (_isScanning) return null;
    _isScanning = true;
    _startError = null;
    _session = null;
    _timer?.cancel();

    if (!_useRealScanner) {
      _timer = Timer(_firstSighting, () {
        _mockSighting();
        _timer = Timer.periodic(_rangingInterval, (_) => _mockSighting());
      });
      notifyListeners();
      return null;
    }

    notifyListeners();
    final source = _sourceOverride ?? IBeaconScanner();
    final error = await source.start(_onHeard);
    if (error != null) {
      _isScanning = false;
      _startError = error;
      notifyListeners();
      return error;
    }
    if (!_isScanning) {
      // Khách đã tắt trong lúc đang chờ cấp quyền.
      await source.stop();
      return null;
    }
    _source = source;
    return null;
  }

  /// Một nhịp quét Bluetooth: chọn beacon gần nhất đã biết hiện vật.
  ///
  /// Backend không chọn hộ khi nghe nhiều beacon cùng lúc — đó là việc của
  /// app. App lấy beacon gần nhất trong phạm vi [AppConfig.beaconMaxMeters];
  /// beacon phục vụ nhiều hiện vật thì ưu tiên hiện vật có thuyết minh.
  Future<void> _onHeard(List<HeardBeacon> heard) async {
    if (!_isScanning) return;
    final near = heard
        .where((h) =>
            h.distanceMeters >= 0 &&
            h.distanceMeters <= AppConfig.beaconMaxMeters)
        .toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    if (near.isEmpty) return;

    await _resolveUnknown(near.map((h) => h.identity));
    if (!_isScanning) return;

    final catalog = ArtifactRepository.instance;
    for (final h in near) {
      final candidate = _resolved[h.identity];
      if (candidate == null || !candidate.resolved) continue;
      final artifacts = [
        for (final id in candidate.artifactIds) ?catalog.tryById(id),
      ];
      if (artifacts.isEmpty) continue;
      final artifact = artifacts.firstWhere(
        (a) => a.hasAudio,
        orElse: () => artifacts.first,
      );
      onBeaconSeen(artifact, beacon: candidate, choices: artifacts);
      return;
    }
  }

  /// Hỏi backend những beacon chưa biết. Beacon backend không nhận ra cũng được
  /// ghi nhớ (`resolved: false`) để không hỏi lại.
  Future<void> _resolveUnknown(Iterable<BeaconIdentity> identities) async {
    final retryAt = _resolveRetryAt;
    if (retryAt != null && _clock().isBefore(retryAt)) return;
    final unknown = [
      for (final id in identities)
        if (!_resolved.containsKey(id) && !_resolving.contains(id)) id,
    ];
    if (unknown.isEmpty) return;
    _resolving.addAll(unknown);
    try {
      final candidates = await BeaconRepository.instance.resolve(unknown);
      // Backend trả đúng thứ tự gửi lên — ghép theo vị trí, không theo chuỗi
      // UUID (hai bên có thể khác hoa/thường).
      for (var i = 0; i < unknown.length && i < candidates.length; i++) {
        _resolved[unknown[i]] = candidates[i];
      }
      _resolveRetryAt = null;
    } on Exception {
      _resolveRetryAt = _clock().add(_resolveBackoff);
    } finally {
      _resolving.removeAll(unknown);
    }
  }

  Future<void> _mockSighting() async {
    if (!_isScanning) return;
    final sighting = await (_session ??= _resolveDemoBeacons());
    if (!_isScanning) return;
    if (sighting != null) {
      onBeaconSeen(sighting.artifact,
          beacon: sighting.beacon,
          source: 'manual',
          choices: sighting.choices);
      return;
    }
    final artifact = _pickArtifact();
    if (artifact == null) return;
    onBeaconSeen(artifact);
  }

  /// Bộ quét giả "nghe" các beacon demo rồi hỏi backend chúng phục vụ hiện vật
  /// nào. Trả `null` khi không gọi được backend hoặc không beacon nào trỏ tới
  /// hiện vật có trong danh mục — bên gọi rơi về cách chọn cũ.
  Future<_Sighting?> _resolveDemoBeacons() async {
    final heard = [
      for (final minor in AppConfig.demoMinors)
        BeaconIdentity(
          proximityUuid: AppConfig.demoProximityUuid,
          major: AppConfig.demoMajor,
          minor: minor,
        ),
    ];
    try {
      final candidates = await BeaconRepository.instance.resolve(heard);
      final catalog = ArtifactRepository.instance;
      final sightings = <_Sighting>[];
      for (final c in candidates.where((c) => c.resolved)) {
        final artifacts = [for (final id in c.artifactIds) ?catalog.tryById(id)];
        for (final artifact in artifacts) {
          sightings.add(_Sighting(artifact, c, artifacts));
        }
      }
      if (sightings.isEmpty) return null;
      // Cùng ưu tiên với bản cũ: hiện vật có thuyết minh trước.
      return sightings.firstWhere(
        (s) => s.artifact.hasAudio,
        orElse: () => sightings.first,
      );
    } on Exception {
      return null;
    }
  }

  /// Một nhịp tín hiệu beacon của [artifact]. Đây là cửa vào duy nhất cho dữ
  /// liệu beacon — bộ quét thật ([_onHeard]) và bộ quét giả đều gọi nó.
  ///
  /// Chỉ đẩy [detected] ở nhịp ĐẦU của một lần ghé: khách đứng nguyên đó thì
  /// mọi nhịp sau đều im, không thì bấm "Để sau" xong hai giây sheet lại bật
  /// lên. Báo lại chỉ khi vừa mất tín hiệu đủ lâu ([awayThreshold] — tức là
  /// khách đã đi khỏi rồi quay lại) vừa cách lần báo trước [repeatCooldown].
  ///
  /// [beacon] là beacon đã phát tín hiệu (đã resolve qua backend) — có thì
  /// lượt ghé được gửi lên backend (`POST /scans`), kèm [artifact] làm hiện
  /// vật được chọn, và vùng beacon đó thành [currentZone].
  ///
  /// [choices] là mọi hiện vật beacon đó phục vụ (có trong danh mục). Từ hai
  /// trở lên thì ở V2 [artifact] chỉ làm khoá chống báo trùng: khách tự chọn
  /// qua [detectedChoices], lượt ghé gửi lên chưa kèm hiện vật (backend vẫn
  /// đếm mức đông) và [reportChoice] gửi bổ sung khi khách chọn.
  void onBeaconSeen(
    Artifact artifact, {
    BeaconCandidate? beacon,
    String source = 'beacon',
    List<Artifact> choices = const [],
  }) {
    if (!_isScanning) return;
    final now = _clock();
    final lastSeen = _lastSeenAt[artifact.id];
    _lastSeenAt[artifact.id] = now;

    final ask = askToChoose && choices.length > 1;
    if (beacon != null) {
      _lastSource = source;
      _reportScan(artifact, beacon.identity, source, now,
          withArtifact: !ask);
      final zoneChanged = currentZone?.beaconId != beacon.beaconId;
      _zone = beacon;
      _zoneSeenAt = now;
      if (zoneChanged) notifyListeners();
    }

    final announcedAt = _announcedAt[artifact.id];
    if (announcedAt != null) {
      final leftArea =
          lastSeen == null || now.difference(lastSeen) >= awayThreshold;
      if (!leftArea) return;
      if (now.difference(announcedAt) < repeatCooldown) return;
    }

    _announcedAt[artifact.id] = now;
    _detected = artifact;
    _detectedChoices = ask ? List.unmodifiable(choices) : const [];
    notifyListeners();
  }

  void _reportScan(
    Artifact artifact,
    BeaconIdentity beacon,
    String source,
    DateTime now, {
    bool withArtifact = true,
  }) {
    final last = _scannedAt[artifact.id];
    if (last != null && now.difference(last) < presenceInterval) return;
    _scannedAt[artifact.id] = now;
    // Không chờ, không báo lỗi: hỏng một lượt ghi thì mất một dòng thống kê,
    // còn khách vẫn phải thấy sheet giới thiệu ngay.
    BeaconRepository.instance
        .recordScan(beacon,
            artifactId: withArtifact ? artifact.id : null, source: source)
        .catchError((Object _) {});
  }

  /// Khách vừa chọn [artifact] trong danh sách hiện vật của beacon: gửi một
  /// lượt ghé kèm hiện vật để backend ghi đúng lịch sử tham quan (lượt tự
  /// động lúc phát hiện chưa biết khách xem hiện vật nào).
  void reportChoice(Artifact artifact) {
    final zone = _zone;
    if (!_isScanning || zone == null) return;
    if (!zone.artifactIds.contains(artifact.id)) return;
    BeaconRepository.instance
        .recordScan(zone.identity, artifactId: artifact.id, source: _lastSource)
        .catchError((Object _) {});
  }

  /// Hiện vật mà beacon mock "phát hiện".
  ///
  /// Ưu tiên hiện vật đã có bản thuyết minh: đây là đường duy nhất trong app
  /// tự động phát audio, nên rơi vào hiện vật chưa có bản thu thì không thử
  /// được luồng đó. Chưa hiện vật nào có audio thì giữ hành vi demo cũ — lấy
  /// hiện vật thứ hai.
  Artifact? _pickArtifact() {
    final all = ArtifactRepository.instance.artifacts;
    if (all.isEmpty) return null;
    for (final artifact in all) {
      if (artifact.hasAudio) return artifact;
    }
    return all.length > 1 ? all[1] : all.first;
  }

  /// Tắt quét là chủ ý của khách nên coi như xong một phiên: bật lại thì hiện
  /// vật ngay cạnh được báo lại từ đầu, không phải chờ hết cooldown.
  void stopScan() {
    _timer?.cancel();
    _source?.stop();
    _source = null;
    _resolved.clear();
    _resolving.clear();
    _resolveRetryAt = null;
    _isScanning = false;
    _detected = null;
    _detectedChoices = const [];
    _lastSeenAt.clear();
    _announcedAt.clear();
    _scannedAt.clear();
    _session = null;
    _zone = null;
    _zoneSeenAt = null;
    notifyListeners();
  }

  /// Bật/tắt quét. Trả về thông báo lỗi khi bật không được.
  Future<String?> toggle() async {
    if (_isScanning) {
      stopScan();
      return null;
    }
    return startScan();
  }

  /// Xoá hiện vật đã phát hiện mà không notify — tránh vòng lặp rebuild khi
  /// bên gọi đang ở trong chính callback của listener.
  void consumeDetection() {
    _detected = null;
    _detectedChoices = const [];
  }

  /// Đồng hồ giả cho test: mô phỏng "đi khỏi rồi vài phút sau quay lại" mà
  /// không phải chờ thật. `tester.pump` chỉ đẩy thời gian của framework chứ
  /// không đụng tới [DateTime.now].
  @visibleForTesting
  set clockForTest(DateTime Function() clock) => _clock = clock;

  @visibleForTesting
  void resetClockForTest() => _clock = DateTime.now;

  /// Thay Bluetooth bằng nguồn tín hiệu giả trong test; `null` để bỏ.
  @visibleForTesting
  set sourceForTest(BeaconSource? source) => _sourceOverride = source;
}

class _Sighting {
  const _Sighting(this.artifact, this.beacon, this.choices);

  final Artifact artifact;
  final BeaconCandidate beacon;

  /// Mọi hiện vật [beacon] phục vụ, gồm cả [artifact].
  final List<Artifact> choices;
}
