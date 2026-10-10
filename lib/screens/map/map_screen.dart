import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import 'attraction_map_screen.dart';
import 'floor_plan_screen.dart';

/// Tab Bản đồ: danh sách điểm tham quan (Attraction) của khu du lịch đang xem.
///
/// Chưa có bản đồ nào ở đây — bấm vào một điểm mới mở bản đồ của điểm đó:
/// - ngoài trời (`OUTDOOR`) → Google Maps ([AttractionMapScreen]);
/// - trong nhà có sơ đồ tầng (`INDOOR`) → ảnh sơ đồ ([FloorPlanScreen]).
///
/// Đổi khu du lịch ở thanh tiêu đề khi có nhiều khu.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ArtifactRepository get _repo => ArtifactRepository.instance;

  /// Khu du lịch đang xem. Khách chưa chọn thì lấy khu đầu tiên có hiện vật.
  String? _areaChoice;

  String? get _areaId {
    final areas = _repo.tourismAreas;
    if (areas.isEmpty) return null;
    if (areas.any((a) => a.id == _areaChoice)) return _areaChoice;
    for (final area in areas) {
      if (_repo.artifactsInArea(area.id).isNotEmpty) return area.id;
    }
    return areas.first.id;
  }

  TourismArea? get _area {
    for (final a in _repo.tourismAreas) {
      if (a.id == _areaId) return a;
    }
    return null;
  }

  /// Điểm tham quan của khu đang xem. Chưa tải được (đang chạy dữ liệu mẫu)
  /// thì gom mọi hiện vật vào một mục để bản đồ vẫn xem được.
  List<Attraction> get _attractions {
    final list = [
      for (final a in _repo.attractions)
        if (_areaId == null || a.tourismAreaId == _areaId) a,
    ];
    if (list.isNotEmpty) return list;
    return const [Attraction(id: '', name: 'Tất cả hiện vật')];
  }

  int _artifactCount(Attraction attraction) => attraction.id.isEmpty
      ? _repo.artifacts.length
      : _repo.artifacts.where((a) => a.attractionId == attraction.id).length;

  /// Điểm tham quan chứa vùng beacon khách đang đứng, nếu có.
  String? get _hereAttractionId {
    final zone = BeaconScanController.instance.currentZone;
    if (zone == null) return null;
    for (final a in _repo.artifacts) {
      if (zone.artifactIds.contains(a.id) && a.attractionId != null) {
        return a.attractionId;
      }
    }
    return null;
  }

  void _open(Attraction attraction) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => attraction.hasFloorPlan
          ? FloorPlanScreen(attraction: attraction)
          : AttractionMapScreen(attraction: attraction),
    ));
  }

  void _pickArea() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Chọn khu tham quan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final area in _repo.tourismAreas)
              ListTile(
                leading:
                    const Icon(Icons.place_outlined, color: AppColors.primary),
                title: Text(area.name),
                subtitle:
                    Text('${_repo.artifactsInArea(area.id).length} hiện vật'),
                trailing: area.id == _areaId
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _areaChoice = area.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArtifactRepository.instance,
        BeaconScanController.instance,
      ]),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final hereId = _hereAttractionId;
    final attractions = _attractions;
    return Scaffold(
      appBar: AppBar(title: _areaTitle()),
      body: RefreshIndicator(
        onRefresh: _repo.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'Chọn một khu vực để xem bản đồ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final attraction in attractions) ...[
              _AttractionButton(
                attraction: attraction,
                artifactCount: _artifactCount(attraction),
                isHere: hereId != null && attraction.id == hereId,
                onTap: () => _open(attraction),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  /// Tiêu đề: tên khu du lịch, bấm để đổi khu khi có nhiều khu.
  Widget _areaTitle() {
    final area = _area;
    if (area == null) return const Text('Bản đồ tham quan');
    final canSwitch = _repo.tourismAreas.length > 1;
    return InkWell(
      onTap: canSwitch ? _pickArea : null,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(area.name, overflow: TextOverflow.ellipsis)),
          if (canSwitch) const Icon(Icons.expand_more),
        ],
      ),
    );
  }
}

/// Một nút khu vực (điểm tham quan) trong danh sách.
class _AttractionButton extends StatelessWidget {
  const _AttractionButton({
    required this.attraction,
    required this.artifactCount,
    required this.isHere,
    required this.onTap,
  });

  final Attraction attraction;
  final int artifactCount;

  /// Khách đang đứng trong vùng beacon của điểm này.
  final bool isHere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final indoor = attraction.hasFloorPlan;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHere ? AppColors.accent : AppColors.divider,
              width: isHere ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  indoor ? Icons.apartment_outlined : Icons.map_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      artifactCount == 0
                          ? 'Chưa có hiện vật'
                          : '$artifactCount hiện vật · '
                              '${indoor ? 'Sơ đồ tầng' : 'Bản đồ'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isHere) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.bluetooth_searching,
                              size: 14, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text(
                            'Bạn đang ở đây',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
