import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../data/crowd_repository.dart';
import '../../data/mock_data.dart';
import '../../services/location_service.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../../widgets/heritage_map.dart';
import '../artifact/artifact_detail_screen.dart';

/// Bản đồ Mapbox của một điểm tham quan ngoài trời: hiện vật, beacon và
/// vùng beacon khách đang đứng.
///
/// Cần token Mapbox lúc build (xem [HeritageMap] / `services/mapbox_config.dart`).
///
/// [attraction] có `id` rỗng nghĩa là "mọi hiện vật" — dùng khi chưa tải được
/// danh sách điểm tham quan (đang chạy dữ liệu mẫu).
class AttractionMapScreen extends StatefulWidget {
  const AttractionMapScreen({super.key, required this.attraction});

  final Attraction attraction;

  @override
  State<AttractionMapScreen> createState() => _AttractionMapScreenState();
}

/// Vùng beacon khách đang đứng, trong phạm vi điểm tham quan này.
typedef _Here = ({String name, MapBeacon? beacon, Set<String> artifactIds});

class _AttractionMapScreenState extends State<AttractionMapScreen> {
  ArtifactRepository get _repo => ArtifactRepository.instance;

  Attraction get _attraction => widget.attraction;

  bool get _isAll => _attraction.id.isEmpty;

  /// Beacon của điểm này (`GET /attractions/:id/map`).
  List<MapBeacon> _beacons = const [];

  /// Mức đông người đổi theo phút — làm mới đều khi bản đồ đang mở.
  static const _crowdRefresh = Duration(seconds: 30);
  Timer? _crowdTimer;

  final _map = HeritageMapController();
  Artifact? _selected;

  /// Bản đồ đã rời khung ôm hết điểm (khách tự kéo/zoom, hoặc vừa zoom tới
  /// vị trí của tôi / vùng beacon) — hiện nút "Xem tất cả".
  bool _movedAway = false;
  Position? _userPos;
  StreamSubscription<Position>? _posSub;
  bool _locating = false;

  /// Đã có quyền vị trí — bật chấm "vị trí của tôi" của Mapbox.
  bool _locationGranted = false;

  static const double _defaultZoom = 18;

  /// Màu ghim: hiện vật đỏ đô (đang chọn: hồng; trong vùng beacon đang đứng:
  /// vàng kim), beacon xanh dương.
  static const _artifactColor = AppColors.primary;
  static const _selectedColor = Color(0xFFE0457B);
  static const _hereColor = AppColors.accent;
  static const _beaconColor = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    _refreshCrowd();
    _crowdTimer = Timer.periodic(_crowdRefresh, (_) => _refreshCrowd());
    _loadBeacons();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _crowdTimer?.cancel();
    super.dispose();
  }

  void _refreshCrowd() => CrowdRepository.instance.refresh(
    attractionId: _isAll ? null : _attraction.id,
  );

  Future<void> _loadBeacons() async {
    if (_isAll) return;
    try {
      final map = await _repo.fetchAttractionMap(_attraction.id);
      if (!mounted) return;
      setState(() => _beacons = map.beacons);
      _fitAll();
    } on Exception {
      // Không có beacon thì vẫn xem được hiện vật.
    }
  }

  // ---- dữ liệu -------------------------------------------------------------

  List<Artifact> get _artifacts => _isAll
      ? _repo.artifacts
      : _repo.artifacts.where((a) => a.attractionId == _attraction.id).toList();

  List<MapBeacon> get _pinnedBeacons => [
    for (final b in _beacons)
      if (b.isPinned) b,
  ];

  /// Mọi điểm có toạ độ của điểm tham quan — để đặt khung nhìn.
  List<(double, double)> get _points => [
    for (final a in _artifacts) (a.lat, a.lng),
    for (final b in _pinnedBeacons) (b.lat!, b.lng!),
  ];

  /// Vùng beacon khách đang đứng, chỉ khi beacon đó thuộc điểm này.
  _Here? get _here {
    final zone = BeaconScanController.instance.currentZone;
    if (zone == null) return null;
    MapBeacon? beacon;
    for (final b in _beacons) {
      if (b.id == zone.beaconId) beacon = b;
    }
    final mine = _artifacts.map((a) => a.id).toSet();
    final ids = zone.artifactIds.where(mine.contains).toSet();
    if (beacon == null && ids.isEmpty) return null;
    return (name: zone.name ?? 'beacon', beacon: beacon, artifactIds: ids);
  }

  /// Dòng phụ trong bong bóng của beacon: mức đông người quanh nó.
  String? _beaconSnippet(MapBeacon beacon) {
    final crowd = CrowdRepository.instance.forBeacon(beacon.id);
    if (crowd == null) return null;
    return crowd.activeDevices == 0
        ? 'Đang vắng khách'
        : '~${crowd.activeDevices} khách quanh đây';
  }

  // ---- camera --------------------------------------------------------------

  void _moveTo(double lat, double lng, {double? zoom}) =>
      _map.moveTo(lat, lng, zoom: zoom);

  void _fitAll() => _map.fit(_points);

  void _onUserMove() {
    if (!_movedAway) setState(() => _movedAway = true);
  }

  /// Nút "Xem tất cả": về khung ôm hết hiện vật và beacon.
  void _showAll() {
    setState(() {
      _movedAway = false;
      _selected = null;
    });
    // Đợi khung sau: đóng thẻ làm đổi padding, khung ôm phải tính theo
    // padding mới.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
  }

  /// Đưa bản đồ về vùng beacon: vị trí beacon nếu có, không thì các hiện vật
  /// nó phục vụ.
  void _goHere(_Here here) {
    setState(() => _movedAway = true);
    final b = here.beacon;
    if (b != null && b.isPinned) {
      _moveTo(b.lat!, b.lng!, zoom: 19);
      return;
    }
    _map.fit([
      for (final a in _artifacts)
        if (here.artifactIds.contains(a.id)) (a.lat, a.lng),
    ]);
  }

  // ---- định vị -------------------------------------------------------------

  /// Xin quyền → lấy vị trí → di chuyển bản đồ tới chỗ người dùng, rồi theo dõi liên tục.
  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final status = await LocationService.ensurePermission();
    if (!mounted) return;

    if (status != LocationStatus.granted) {
      setState(() => _locating = false);
      _showLocationMessage(status);
      return;
    }

    try {
      final pos = await LocationService.current();
      if (!mounted) return;
      setState(() {
        _userPos = pos;
        _locating = false;
        _locationGranted = true;
        _movedAway = true;
      });
      _moveTo(pos.latitude, pos.longitude, zoom: _defaultZoom);
      _posSub ??= LocationService.stream().listen((p) {
        if (mounted) setState(() => _userPos = p);
      });
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationMessage(LocationStatus status) {
    final msg = switch (status) {
      LocationStatus.serviceDisabled =>
        'Vui lòng bật GPS/Vị trí trên thiết bị rồi thử lại.',
      LocationStatus.deniedForever =>
        'Quyền vị trí đang bị chặn. Hãy bật lại trong Cài đặt của máy.',
      _ => 'Ứng dụng cần quyền vị trí để định vị bạn trên bản đồ.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(errorSnackBar(msg));
  }

  // ---- giao diện -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArtifactRepository.instance,
        CrowdRepository.instance,
        BeaconScanController.instance,
      ]),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final here = _here;
    final hasPoints = _points.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_attraction.name, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          if (!hasPoints)
            const MapMessage(
              icon: Icons.location_off_outlined,
              title: 'Chưa có vị trí trên bản đồ',
              text:
                  'Điểm tham quan này chưa có hiện vật hay beacon nào được '
                  'đặt toạ độ.',
            )
          else
            HeritageMap(
              controller: _map,
              initialFit: _points,
              singlePointZoom: 19,
              showUserLocation: _locationGranted,
              // Chừa chỗ cho dải phía trên và thẻ hiện vật phía dưới để logo
              // Mapbox và la bàn không bị che.
              padding: EdgeInsets.only(
                top: here == null ? 0 : 56,
                bottom: _selected == null ? 0 : 150,
              ),
              onMapTap: () {
                if (_selected != null) setState(() => _selected = null);
              },
              onUserMove: _onUserMove,
              zone: _zone(here),
              pins: _pins(here),
            ),

          // "Bạn đang ở khu vực Beacon …" — bấm để đưa bản đồ về đó.
          if (here != null && hasPoints)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _goHere(here),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bluetooth_searching,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Bạn đang ở khu vực ${here.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Thẻ thông tin hiện vật đang chọn
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _MapArtifactCard(
                artifact: _selected!,
                userPos: _userPos,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
      floatingActionButton: hasPoints
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_movedAway) ...[
                  MapFitAllButton(onPressed: _showAll),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  onPressed: _locating ? null : _locateMe,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: _locating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            )
          : null,
    );
  }

  /// Vùng beacon khách đang đứng (khi beacon đã có toạ độ).
  MapZone? _zone(_Here? here) {
    final b = here?.beacon;
    if (b == null || !b.isPinned) return null;
    return MapZone(
      lat: b.lat!,
      lng: b.lng!,
      radiusMeters: 15,
      color: AppColors.accent,
    );
  }

  /// Hiện vật và beacon. Bấm hiện vật mở thẻ ở đáy; bấm beacon báo tên và mức
  /// đông người quanh nó (Mapbox không có bong bóng sẵn như Google Maps).
  List<MapPin> _pins(_Here? here) {
    return [
      for (final b in _pinnedBeacons)
        MapPin(
          id: 'beacon:${b.id}',
          lat: b.lat!,
          lng: b.lng!,
          title: b.name,
          color: _beaconColor,
          sortKey: 1,
          onTap: () => _showBeacon(b),
        ),
      for (final artifact in _artifacts)
        MapPin(
          id: 'artifact:${artifact.id}',
          lat: artifact.lat,
          lng: artifact.lng,
          title: artifact.name,
          color: _selected?.id == artifact.id
              ? _selectedColor
              : (here?.artifactIds.contains(artifact.id) ?? false)
              ? _hereColor
              : _artifactColor,
          sortKey: _selected?.id == artifact.id ? 3 : 2,
          onTap: () {
            setState(() => _selected = artifact);
            _moveTo(artifact.lat, artifact.lng);
          },
        ),
    ];
  }

  void _showBeacon(MapBeacon beacon) {
    final snippet = _beaconSnippet(beacon);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            snippet == null ? beacon.name : '${beacon.name} · $snippet',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

class _MapArtifactCard extends StatelessWidget {
  const _MapArtifactCard({
    required this.artifact,
    required this.userPos,
    required this.onClose,
  });

  final Artifact artifact;
  final Position? userPos;
  final VoidCallback onClose;

  /// Chuỗi khoảng cách từ người dùng tới hiện vật (nếu đã có GPS).
  String get _distanceLabel {
    if (userPos == null) return artifact.zone;
    final meters = LocationService.distanceMeters(
      userPos!.latitude,
      userPos!.longitude,
      artifact.lat,
      artifact.lng,
    );
    final dist = meters < 1000
        ? '${meters.round()}m'
        : '${(meters / 1000).toStringAsFixed(1)}km';
    return '${artifact.zone} · cách bạn ~$dist';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ArtifactThumb(artifact: artifact, size: 56, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _distanceLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (CrowdRepository.instance.forArtifact(artifact.id)
                        case final crowd?) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              crowd.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.directions_walk, size: 19),
                  label: const Text(
                    'Chỉ đường',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArtifactDetailScreen(artifact: artifact),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.info_outline, size: 19),
                  label: const Text('Chi tiết', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
