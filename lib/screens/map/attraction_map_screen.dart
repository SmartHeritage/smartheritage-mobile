import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../data/crowd_repository.dart';
import '../../data/mock_data.dart';
import '../../services/location_service.dart';
import '../../services/maps_config.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';

/// Bản đồ Google Maps của một điểm tham quan ngoài trời: hiện vật, beacon và
/// vùng beacon khách đang đứng.
///
/// Cần khoá Google Maps SDK: `GOOGLE_MAPS_API_KEY` trong
/// `android/local.properties` và `ios/Flutter/Secrets.xcconfig` (cả hai đều
/// nằm ngoài git).
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

  GoogleMapController? _map;
  Artifact? _selected;
  Position? _userPos;
  StreamSubscription<Position>? _posSub;
  bool _locating = false;

  /// Đã có quyền vị trí — bật chấm xanh "vị trí của tôi" của Google Maps.
  bool _locationGranted = false;

  /// `flutter test` không có Google Maps SDK native — thay nền bản đồ bằng một
  /// danh sách ghim bấm được ([_TestMapStub]), phần còn lại vẫn chạy thật.
  static final bool _inWidgetTest = Platform.environment.containsKey(
    'FLUTTER_TEST',
  );

  static const double _defaultZoom = 18;

  /// `null` khi đang hỏi phía native; `false` = chưa cấu hình khoá Google Maps.
  bool? _mapsConfigured;

  @override
  void initState() {
    super.initState();
    _refreshCrowd();
    _crowdTimer = Timer.periodic(_crowdRefresh, (_) => _refreshCrowd());
    _loadBeacons();
    if (!_inWidgetTest) {
      MapsConfig.isConfigured().then((ok) {
        if (mounted) setState(() => _mapsConfigured = ok);
      });
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _crowdTimer?.cancel();
    _map?.dispose();
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
  List<LatLng> get _points => [
    for (final a in _artifacts) LatLng(a.lat, a.lng),
    for (final b in _pinnedBeacons) LatLng(b.lat!, b.lng!),
  ];

  LatLng get _center {
    final points = _points;
    if (points.isEmpty) {
      return const LatLng(MockData.siteLat, MockData.siteLng);
    }
    return LatLng(
      points.map((p) => p.latitude).reduce((x, y) => x + y) / points.length,
      points.map((p) => p.longitude).reduce((x, y) => x + y) / points.length,
    );
  }

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

  void _moveTo(LatLng target, {double? zoom}) {
    _map?.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(target)
          : CameraUpdate.newLatLngZoom(target, zoom),
    );
  }

  /// Đưa khung nhìn bao trọn [points]; một điểm thì zoom vào điểm đó.
  void _fit(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _moveTo(points.single, zoom: 19);
      return;
    }
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    _map?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        72,
      ),
    );
  }

  void _fitAll() => _fit(_points);

  /// Đưa bản đồ về vùng beacon: vị trí beacon nếu có, không thì các hiện vật
  /// nó phục vụ.
  void _goHere(_Here here) {
    final b = here.beacon;
    if (b != null && b.isPinned) {
      _moveTo(LatLng(b.lat!, b.lng!), zoom: 19);
      return;
    }
    _fit([
      for (final a in _artifacts)
        if (here.artifactIds.contains(a.id)) LatLng(a.lat, a.lng),
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
      });
      _moveTo(LatLng(pos.latitude, pos.longitude), zoom: _defaultZoom);
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
    final markers = _markers(here);
    final hasPoints = _points.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_attraction.name, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          if (!hasPoints)
            const _Message(
              icon: Icons.location_off_outlined,
              title: 'Chưa có vị trí trên bản đồ',
              text:
                  'Điểm tham quan này chưa có hiện vật hay beacon nào được '
                  'đặt toạ độ.',
            )
          else if (_inWidgetTest)
            _TestMapStub(markers: markers)
          else if (_mapsConfigured == null)
            const ColoredBox(
              color: AppColors.surfaceTint,
              child: SizedBox.expand(),
            )
          else if (_mapsConfigured == false)
            const _Message(
              icon: Icons.map_outlined,
              title: 'Bản đồ chưa sẵn sàng',
              text:
                  'Bản build này chưa có khoá Google Maps. Thêm '
                  'GOOGLE_MAPS_API_KEY vào android/local.properties và '
                  'ios/Flutter/Secrets.xcconfig rồi build lại.',
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: _defaultZoom,
              ),
              minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
              myLocationEnabled: _locationGranted,
              // Đã có nút định vị riêng (FAB) và thẻ hiện vật.
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              // Chừa chỗ cho dải phía trên và thẻ hiện vật phía dưới để logo
              // Google và la bàn không bị che.
              padding: EdgeInsets.only(
                top: here == null ? 0 : 56,
                bottom: _selected == null ? 0 : 150,
              ),
              onMapCreated: (controller) {
                _map = controller;
                _fitAll();
              },
              onTap: (_) {
                if (_selected != null) setState(() => _selected = null);
              },
              circles: _circles(here),
              markers: markers,
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
          ? FloatingActionButton(
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
            )
          : null,
    );
  }

  /// Vùng beacon khách đang đứng (khi beacon đã có toạ độ).
  Set<Circle> _circles(_Here? here) {
    final b = here?.beacon;
    if (b == null || !b.isPinned) return const {};
    return {
      Circle(
        circleId: const CircleId('here'),
        center: LatLng(b.lat!, b.lng!),
        radius: 15,
        fillColor: AppColors.accent.withValues(alpha: 0.18),
        strokeColor: AppColors.accent,
        strokeWidth: 2,
      ),
    };
  }

  /// Hiện vật (đỏ; đang chọn: hồng; trong vùng beacon đang đứng: cam) và
  /// beacon (xanh, bong bóng ghi mức đông người).
  Set<Marker> _markers(_Here? here) {
    return {
      for (final b in _pinnedBeacons)
        Marker(
          markerId: MarkerId('beacon:${b.id}'),
          position: LatLng(b.lat!, b.lng!),
          zIndexInt: 1,
          alpha: here?.beacon?.id == b.id ? 1 : 0.85,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: b.name, snippet: _beaconSnippet(b)),
        ),
      for (final artifact in _artifacts)
        Marker(
          markerId: MarkerId('artifact:${artifact.id}'),
          position: LatLng(artifact.lat, artifact.lng),
          zIndexInt: _selected?.id == artifact.id ? 3 : 2,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selected?.id == artifact.id
                ? BitmapDescriptor.hueRose
                : (here?.artifactIds.contains(artifact.id) ?? false)
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          // Tên hiện vật cho trình đọc màn hình; thông tin đầy đủ ở thẻ dưới.
          infoWindow: InfoWindow(title: artifact.name),
          // Không mở bong bóng: thông tin hiện ở thẻ phía dưới.
          consumeTapEvents: true,
          onTap: () {
            setState(() => _selected = artifact);
            _moveTo(LatLng(artifact.lat, artifact.lng));
          },
        ),
    };
  }
}

/// Thông báo thay cho bản đồ (chưa có vị trí, chưa có khoá…).
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceTint,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thay Google Maps trong `flutter test`: mỗi ghim là một nút bấm, bấm vào
/// chạy đúng hành vi của ghim (hoặc của bong bóng, nếu ghim mở bong bóng).
class _TestMapStub extends StatelessWidget {
  const _TestMapStub({required this.markers});

  final Set<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceTint,
      child: ListView(
        padding: const EdgeInsets.only(top: 120, bottom: 200),
        children: [
          for (final m in markers)
            TextButton(
              key: ValueKey(m.markerId.value),
              onPressed: m.onTap ?? m.infoWindow.onTap,
              child: Text(m.infoWindow.title ?? m.markerId.value),
            ),
        ],
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
