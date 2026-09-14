import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock_data.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';

/// Bản đồ khu di tích thật (tiles CARTO, dữ liệu OpenStreetMap) + định vị GPS.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _siteCenter = LatLng(MockData.siteLat, MockData.siteLng);

  final MapController _mapController = MapController();
  Artifact? _selected;
  Position? _userPos;
  StreamSubscription<Position>? _posSub;
  bool _locating = false;
  String _zone = 'Tất cả';

  static const _zones = [
    'Tất cả',
    'Khu trưng bày A',
    'Khu trưng bày B',
    'Khu trưng bày C',
    'Sân ngoài trời',
  ];

  List<Artifact> get _visibleArtifacts => _zone == 'Tất cả'
      ? MockData.artifacts
      : MockData.artifacts.where((a) => a.zone == _zone).toList();

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

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
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
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
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ tham quan'),
      ),
      body: Stack(
        children: [
          // 1) Nền bản đồ thật (tiles CARTO)
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _siteCenter,
              initialZoom: 17,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              // Tiles của CARTO (dữ liệu vẫn từ OpenStreetMap). Không dùng
              // public tile server của OSM: usage policy của họ không cho phép
              // dùng cho app thật.
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartheritage.smartheritage',
                maxNativeZoom: 20,
              ),

              // 3) Vòng độ chính xác + chấm vị trí người dùng
              if (_userPos != null) ...[
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(_userPos!.latitude, _userPos!.longitude),
                      radius: _userPos!.accuracy,
                      useRadiusInMeter: true,
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderColor: AppColors.accent.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_userPos!.latitude, _userPos!.longitude),
                      width: 80,
                      height: 80,
                      child: const RadarPulse(size: 80),
                    ),
                  ],
                ),
              ],

              // 2) Ghim các hiện vật
              MarkerLayer(
                markers: [
                  for (final artifact in _visibleArtifacts)
                    Marker(
                      point: LatLng(artifact.lat, artifact.lng),
                      width: 52,
                      height: 52,
                      child: _MapPin(
                        artifact: artifact,
                        selected: _selected?.id == artifact.id,
                        onTap: () {
                          setState(() => _selected = artifact);
                          _mapController.move(
                            LatLng(artifact.lat, artifact.lng),
                            _mapController.camera.zoom,
                          );
                        },
                      ),
                    ),
                ],
              ),

              // License của CARTO buộc ghi nguồn cả CARTO và OpenStreetMap.
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('CARTO'),
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Thanh lọc khu vực (nổi phía trên)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final zone in _zones)
                    _zoneChip(zone, selected: _zone == zone),
                ],
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
      floatingActionButton: FloatingActionButton(
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
    );
  }

  Widget _zoneChip(String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          _zone = label;
          if (_selected != null && _selected!.zone != label && label != 'Tất cả') {
            _selected = null;
          }
        }),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.artifact,
    required this.selected,
    required this.onTap,
  });

  final Artifact artifact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 50 : 44,
        height: selected ? 50 : 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : AppColors.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          artifact.icon,
          size: 22,
          color: selected ? Colors.white : AppColors.primary,
        ),
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
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close,
                    size: 20, color: AppColors.textSecondary),
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
                  label: const Text('Chỉ đường',
                      style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ArtifactDetailScreen(artifact: artifact),
                  )),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.info_outline, size: 19),
                  label:
                      const Text('Chi tiết', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
