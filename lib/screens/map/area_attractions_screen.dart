import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../data/crowd_repository.dart';
import '../../l10n/l10n.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import 'attraction_map_screen.dart';
import 'floor_plan_screen.dart';
import 'floor_screen.dart';

/// Danh sách điểm tham quan (Attraction) của một khu du lịch — mở từ ghim
/// trên bản đồ tất cả địa điểm ([MapScreen]).
///
/// Khu du lịch có tầng (`GET /tourism-areas/:id/floors`) thì liệt kê **tầng**
/// trước; chọn tầng mới mở sơ đồ tầng với các khối khu vực ([FloorScreen]).
/// Khu vực không thuộc tầng nào nằm ở mục "Khu vực khác" bên dưới. Không có
/// tầng (hay không tải được) thì liệt kê thẳng khu vực như trước.
///
/// Bấm vào một điểm mới mở bản đồ của điểm đó:
/// - ngoài trời (`OUTDOOR`) → bản đồ Mapbox ([AttractionMapScreen]);
/// - trong nhà có sơ đồ tầng (`INDOOR`) → ảnh sơ đồ ([FloorPlanScreen]).
///
/// [area] `null` = chưa tải được khu du lịch nào (đang chạy dữ liệu mẫu): gom
/// mọi hiện vật vào một nút. Khi đó màn này chính là tab Bản đồ.
///
/// Mỗi nút kèm mức đông người của điểm đó (`GET /attractions/:id/crowd`).
class AreaAttractionsScreen extends StatefulWidget {
  const AreaAttractionsScreen({super.key, this.area});

  final TourismArea? area;

  @override
  State<AreaAttractionsScreen> createState() => _AreaAttractionsScreenState();
}

class _AreaAttractionsScreenState extends State<AreaAttractionsScreen> {
  ArtifactRepository get _repo => ArtifactRepository.instance;

  /// Backend coi máy "đang có mặt" trong 5 phút, nên làm mới mỗi phút là đủ.
  /// Màn này luôn sống trong IndexedStack, đừng hạ chu kỳ xuống quá thấp.
  static const _crowdRefresh = Duration(seconds: 60);
  Timer? _crowdTimer;

  /// Bộ id điểm tham quan đã tải mức đông lần gần nhất — đổi khu hay danh mục
  /// vừa tải xong thì tải lại ngay, không chờ hết chu kỳ.
  String? _crowdKey;

  /// Tầng của khu du lịch; `null` = đang tải. Lỗi hay khu mock thì rỗng.
  List<Floor>? _floors;

  @override
  void initState() {
    super.initState();
    _crowdTimer = Timer.periodic(_crowdRefresh, (_) => _refreshCrowd());
    _loadFloors();
  }

  Future<void> _loadFloors() async {
    final area = widget.area;
    if (area == null) {
      _floors = const [];
      return;
    }
    List<Floor> floors;
    try {
      floors = await _repo.fetchFloors(area.id);
    } on Exception {
      // Mất mạng / backend cũ chưa có route: vẫn xem được danh sách khu vực.
      floors = const [];
    }
    if (mounted) setState(() => _floors = floors);
  }

  @override
  void dispose() {
    _crowdTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshCrowd() => CrowdRepository.instance.refreshAttractions(
    _attractions.map((a) => a.id),
  );

  /// Gọi trong build: danh sách điểm đổi thì tải mức đông sau frame này.
  void _syncCrowd(List<Attraction> attractions) {
    final key = attractions.map((a) => a.id).join(',');
    if (key == _crowdKey) return;
    _crowdKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshCrowd();
    });
  }

  Future<void> _pullToRefresh() async {
    await _repo.refresh();
    await Future.wait([_refreshCrowd(), _loadFloors()]);
  }

  Future<void> _openFloor(Floor floor) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FloorScreen(floor: floor)));
    if (mounted) _refreshCrowd();
  }

  String? get _areaId => widget.area?.id;

  /// Điểm tham quan của khu đang xem. Chưa tải được (đang chạy dữ liệu mẫu)
  /// thì gom mọi hiện vật vào một mục để bản đồ vẫn xem được.
  List<Attraction> get _attractions {
    final list = [
      for (final a in _repo.attractions)
        if (_areaId == null || a.tourismAreaId == _areaId) a,
    ];
    if (list.isNotEmpty) return list;
    return [Attraction(id: '', name: context.l10n.mapAllArtifacts)];
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

  Future<void> _open(Attraction attraction) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => attraction.hasFloorPlan
            ? FloorPlanScreen(attraction: attraction)
            : AttractionMapScreen(attraction: attraction),
      ),
    );
    // Quay lại danh sách: số có thể đã cũ sau một lúc xem bản đồ.
    if (mounted) _refreshCrowd();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArtifactRepository.instance,
        BeaconScanController.instance,
        CrowdRepository.instance,
      ]),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final hereId = _hereAttractionId;
    final attractions = _attractions;
    _syncCrowd(attractions);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.area?.name ?? context.l10n.mapScreenTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _floors == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _pullToRefresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: _floors!.isEmpty
                    ? _attractionList(
                        attractions,
                        hereId,
                        hint: context.l10n.mapPickArea,
                      )
                    : _floorList(_floors!, attractions, hereId),
              ),
            ),
    );
  }

  List<Widget> _floorList(
    List<Floor> floors,
    List<Attraction> attractions,
    String? hereId,
  ) {
    final floorIds = floors.map((f) => f.id).toSet();
    final loose = [
      for (final a in attractions)
        if (a.id.isNotEmpty && !floorIds.contains(a.floorId)) a,
    ];
    return [
      _Hint(context.l10n.mapPickFloor),
      for (final floor in floors) ...[
        _FloorButton(
          floor: floor,
          attractions: [
            for (final a in attractions)
              if (a.floorId == floor.id) a,
          ],
          hereId: hereId,
          onTap: () => _openFloor(floor),
        ),
        const SizedBox(height: 10),
      ],
      if (loose.isNotEmpty) ...[
        const SizedBox(height: 8),
        ..._attractionList(loose, hereId, hint: context.l10n.mapOtherAreas),
      ],
    ];
  }

  List<Widget> _attractionList(
    List<Attraction> attractions,
    String? hereId, {
    required String hint,
  }) {
    return [
      _Hint(hint),
      for (final attraction in attractions) ...[
        _AttractionButton(
          attraction: attraction,
          artifactCount: _artifactCount(attraction),
          isHere: hereId != null && attraction.id == hereId,
          crowd: CrowdRepository.instance.forAttraction(attraction.id),
          onTap: () => _open(attraction),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Một nút tầng: tên, số khu vực, nền (sơ đồ/bản đồ), "Bạn đang ở đây".
class _FloorButton extends StatelessWidget {
  const _FloorButton({
    required this.floor,
    required this.attractions,
    required this.hereId,
    required this.onTap,
  });

  final Floor floor;
  final List<Attraction> attractions;
  final String? hereId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHere = hereId != null && attractions.any((a) => a.id == hereId);
    final count = attractions.length;
    final base = floor.floorPlanUrl != null
        ? context.l10n.mapFloorPlan
        : context.l10n.navMap;
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
                child: const Icon(
                  Icons.layers_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floor.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${context.l10n.mapAreaCount(count)} · $base',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isHere) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.bluetooth_searching,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.mapOnThisFloor,
                            style: const TextStyle(
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

/// Một nút khu vực (điểm tham quan) trong danh sách.
class _AttractionButton extends StatelessWidget {
  const _AttractionButton({
    required this.attraction,
    required this.artifactCount,
    required this.isHere,
    required this.onTap,
    this.crowd,
  });

  final Attraction attraction;
  final int artifactCount;

  /// Mức đông người; `null` khi chưa tải được (mock, mất mạng).
  final AttractionCrowd? crowd;

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
                          ? context.l10n.mapNoArtifacts
                          : '${context.l10n.mapArtifactCount(artifactCount)} · '
                                '${indoor ? context.l10n.mapFloorPlan : context.l10n.navMap}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (crowd case final crowd? when crowd.isMeasurable) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 15,
                            color: crowd.activeDevices == 0
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            crowd.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: crowd.activeDevices == 0
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isHere) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.bluetooth_searching,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.mapYouAreHere,
                            style: const TextStyle(
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
