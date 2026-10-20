import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/heritage_map.dart';
import 'area_attractions_screen.dart';

/// Tab Bản đồ: bản đồ Mapbox với mọi khu du lịch (địa điểm) đã có vị trí.
///
/// Bấm ghim → thẻ địa điểm ở đáy → "Xem các khu vực" mở danh sách điểm tham
/// quan của nó ([AreaAttractionsScreen]), từ đó vào bản đồ/sơ đồ từng khu.
/// Địa điểm chưa chấm vị trí vẫn mở được qua nút danh sách ở góc trên.
///
/// Chưa tải được khu du lịch nào (dữ liệu mẫu) thì tab này là thẳng danh sách
/// "Tất cả hiện vật" như trước.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ArtifactRepository get _repo => ArtifactRepository.instance;

  final _map = HeritageMapController();
  String? _selectedId;

  /// Khách đã tự kéo/zoom khỏi khung ban đầu — hiện nút "Xem tất cả".
  bool _movedAway = false;

  /// Zoom khi chỉ có một địa điểm / tối đa khi ôm nhiều địa điểm sát nhau:
  /// đủ thấy cả khuôn viên, chưa sát tới từng toà nhà.
  static const double _areaZoom = 15;

  /// Ghim địa điểm to gấp rưỡi ghim thường: ít ghim, ảnh bìa nhìn rõ hơn.
  static const double _areaPinScale = 1.5;

  /// Khu du lịch chứa vùng beacon khách đang đứng, nếu có.
  String? get _hereAreaId {
    final zone = BeaconScanController.instance.currentZone;
    if (zone == null) return null;
    final attractionArea = {
      for (final a in _repo.attractions) a.id: a.tourismAreaId,
    };
    for (final artifact in _repo.artifacts) {
      if (!zone.artifactIds.contains(artifact.id)) continue;
      final areaId = attractionArea[artifact.attractionId];
      if (areaId != null) return areaId;
    }
    return null;
  }

  int _attractionCount(TourismArea area) =>
      _repo.attractions.where((a) => a.tourismAreaId == area.id).length;

  void _open(TourismArea area) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AreaAttractionsScreen(area: area),
    ));
  }

  void _select(TourismArea area) {
    setState(() => _selectedId = area.id);
    _map.moveTo(area.lat!, area.lng!);
  }

  void _onUserMove() {
    if (!_movedAway) setState(() => _movedAway = true);
  }

  /// Về khung ôm hết các địa điểm, như lúc mới mở bản đồ.
  void _fitAll(List<TourismArea> pinned) {
    setState(() {
      _movedAway = false;
      _selectedId = null;
    });
    // Đợi khung sau: đóng thẻ làm đổi padding, khung ôm phải tính theo
    // padding mới, không thì chừa thừa chỗ cho thẻ đã đóng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _map.fit([for (final a in pinned) (a.lat!, a.lng!)]);
    });
  }

  /// Mọi địa điểm, kể cả chưa có vị trí (không có ghim trên bản đồ).
  void _showList(String? hereId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Địa điểm tham quan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              for (final area in _repo.tourismAreas)
                _AreaTile(
                  area: area,
                  subtitle: _subtitle(area),
                  isHere: area.id == hereId,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _open(area);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(TourismArea area) {
    final count = _attractionCount(area);
    final parts = [
      count == 0 ? 'Chưa có khu vực' : '$count khu vực',
      '${_repo.artifactsInArea(area.id).length} hiện vật',
      if (!area.isPinned) 'chưa có vị trí trên bản đồ',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArtifactRepository.instance,
        BeaconScanController.instance,
      ]),
      builder: (context, _) {
        if (_repo.tourismAreas.isEmpty) return const AreaAttractionsScreen();
        return _buildScaffold(context);
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final areas = _repo.tourismAreas;
    final pinned = [
      for (final a in areas)
        if (a.isPinned) a,
    ];
    final hereId = _hereAreaId;
    // Thanh điều hướng kính mờ nổi đè lên đáy màn (MainShell bật extendBody).
    final navInset = MediaQuery.paddingOf(context).bottom;
    TourismArea? selected;
    TourismArea? here;
    for (final a in pinned) {
      if (a.id == _selectedId) selected = a;
      if (a.id == hereId) here = a;
    }

    if (pinned.isEmpty) {
      // Không có bản đồ để xem — danh sách thường, giữ thanh tiêu đề.
      return Scaffold(
        appBar: AppBar(title: const Text('Bản đồ tham quan')),
        body: _UnpinnedList(
          areas: areas,
          subtitle: _subtitle,
          hereId: hereId,
          onOpen: _open,
        ),
      );
    }

    // Bản đồ tràn cả màn (không thanh tiêu đề) — nút nổi tránh tai thỏ.
    final topInset = MediaQuery.paddingOf(context).top;
    // Cột nút góc phải: danh sách (40) + "Xem tất cả" (8 + 40) khi có.
    final buttonsHeight = 40.0 + (_movedAway ? 48 : 0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Nền bản đồ sáng → chữ thanh trạng thái tối.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            HeritageMap(
              controller: _map,
              initialFit: [for (final a in pinned) (a.lat!, a.lng!)],
              singlePointZoom: _areaZoom,
              maxFitZoom: _areaZoom,
              padding: EdgeInsets.only(
                // La bàn Mapbox (góc trên phải) nằm dưới cột nút.
                top: topInset + 12 + buttonsHeight,
                // Thẻ có ảnh bìa + mô tả nên cao hơn thẻ hiện vật.
                bottom: navInset + (selected == null ? 0 : 330),
              ),
              onMapTap: () {
                if (_selectedId != null) setState(() => _selectedId = null);
              },
              onUserMove: _onUserMove,
              pins: [
                for (final area in pinned)
                  MapPin(
                    id: 'area:${area.id}',
                    lat: area.lat!,
                    lng: area.lng!,
                    title: area.name,
                    label: area.name,
                    color: area.id == _selectedId
                        ? AppColors.primaryDark
                        : area.id == hereId
                        ? AppColors.accent
                        : AppColors.primary,
                    sortKey: area.id == _selectedId ? 2 : 1,
                    imageUrl: area.imageUrl,
                    scale: _areaPinScale,
                    onTap: () => _select(area),
                  ),
              ],
            ),

            Positioned(
              top: topInset + 12,
              left: 16,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Bạn đang ở …" — bấm để đưa bản đồ về địa điểm đó.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: switch (here) {
                        null => null,
                        final here => Padding(
                          // Canh giữa với nút tròn 40 bên phải.
                          padding: const EdgeInsets.only(top: 2),
                          child: _HereChip(
                            text: 'Bạn đang ở ${here.name}',
                            onTap: () => _select(here),
                          ),
                        ),
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Đặt trên cùng thay vì cạnh thẻ ở đáy: đáy phải có logo và
                  // nút (i) của Mapbox, dễ đè lên nhau.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapIconButton(
                        icon: Icons.format_list_bulleted,
                        tooltip: 'Danh sách địa điểm',
                        onPressed: () => _showList(hereId),
                      ),
                      if (_movedAway) ...[
                        const SizedBox(height: 8),
                        MapFitAllButton(onPressed: () => _fitAll(pinned)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (selected case final selected?)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + navInset,
                child: _AreaCard(
                  area: selected,
                  subtitle: _subtitle(selected),
                  isHere: selected.id == hereId,
                  onOpen: () => _open(selected),
                  onClose: () => setState(() => _selectedId = null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Không địa điểm nào có vị trí: không có gì để vẽ — liệt kê thẳng ra.
class _UnpinnedList extends StatelessWidget {
  const _UnpinnedList({
    required this.areas,
    required this.subtitle,
    required this.hereId,
    required this.onOpen,
  });

  final List<TourismArea> areas;
  final String Function(TourismArea) subtitle;
  final String? hereId;
  final void Function(TourismArea) onOpen;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: ArtifactRepository.instance.refresh,
      child: ListView(
        padding: EdgeInsets.only(
          top: 12,
          bottom: 12 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Chưa có địa điểm nào được đặt vị trí trên bản đồ. Chọn một '
              'địa điểm để xem các khu vực.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          for (final area in areas)
            _AreaTile(
              area: area,
              subtitle: subtitle(area),
              isHere: area.id == hereId,
              onTap: () => onOpen(area),
            ),
        ],
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.area,
    required this.subtitle,
    required this.isHere,
    required this.onTap,
  });

  final TourismArea area;
  final String subtitle;
  final bool isHere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = area.imageUrl;
    return ListTile(
      leading: image == null
          ? Icon(
              isHere ? Icons.bluetooth_searching : Icons.place_outlined,
              color: isHere ? AppColors.accent : AppColors.primary,
            )
          : _AreaImage(url: image, size: 44, radius: 10),
      title: Text(area.name),
      subtitle: Text(isHere ? 'Bạn đang ở đây · $subtitle' : subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _HereChip extends StatelessWidget {
  const _HereChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  text,
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
    );
  }
}

/// Ảnh bìa địa điểm; tải lỗi (404, mất mạng) thì là ô màu có biểu tượng.
class _AreaImage extends StatelessWidget {
  const _AreaImage({
    required this.url,
    required this.size,
    required this.radius,
    this.height,
  });

  final String url;
  final double size;
  final double radius;

  /// Cao khác rộng (ảnh bìa trong thẻ); `null` = vuông [size].
  final double? height;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.surfaceTint,
      child: Center(
        child: Icon(
          Icons.account_balance_outlined,
          color: AppColors.primary,
          size: size > 60 ? 36 : 22,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: height ?? size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : placeholder,
        ),
      ),
    );
  }
}

/// Thẻ địa điểm đang chọn ở đáy bản đồ: ảnh bìa, địa chỉ, mô tả.
class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.subtitle,
    required this.isHere,
    required this.onOpen,
    required this.onClose,
  });

  final TourismArea area;
  final String subtitle;
  final bool isHere;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final image = area.imageUrl;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              if (image != null)
                LayoutBuilder(
                  builder: (context, constraints) => _AreaImage(
                    url: image,
                    size: constraints.maxWidth,
                    height: 130,
                    radius: 0,
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: image == null
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Đóng',
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: image == null
                          ? AppColors.textSecondary
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              // Không ảnh thì tiêu đề nằm ngang hàng nút đóng — chừa chỗ cho nó.
              if (image == null) const SizedBox(height: 48),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, image == null ? 0 : 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  area.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (area.address case final address?) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  isHere ? 'Bạn đang ở đây · $subtitle' : subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isHere ? FontWeight.w600 : FontWeight.normal,
                    color: isHere ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
                if (area.description case final description?) ...[
                  const SizedBox(height: 8),
                  // Mô tả admin viết có thể dài — thẻ chỉ tóm tắt vài dòng.
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 19),
                  label: const Text(
                    'Xem các khu vực',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
