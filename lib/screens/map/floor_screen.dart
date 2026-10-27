import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../l10n/l10n.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/heritage_map.dart';
import 'attraction_map_screen.dart';
import 'floor_plan_screen.dart';

/// Sơ đồ một tầng của khu du lịch, với các khu vực là khối admin đã vẽ.
///
/// - Tầng có ảnh sơ đồ → ảnh + khối theo tỉ lệ 0..1 ([Attraction.planBlock]);
/// - tầng không có ảnh → bản đồ Mapbox + khối theo lat/lng
///   ([Attraction.mapBlock]).
///
/// Bấm khối mở sơ đồ/bản đồ riêng của khu vực đó, như nút khu vực ở
/// danh sách. Dải nút dưới cùng liệt kê mọi khu vực của tầng — khu vực chưa vẽ
/// khối vẫn mở được.
class FloorScreen extends StatelessWidget {
  const FloorScreen({super.key, required this.floor});

  final Floor floor;

  /// Màu khối xoay vòng để các khu vực sát nhau vẫn phân biệt được.
  static const _palette = [
    AppColors.primary,
    Color(0xFF1E88E5),
    Color(0xFF2E7D4F),
    Color(0xFF8E44AD),
    Color(0xFFE67E22),
  ];

  static Color colorAt(int i) => _palette[i % _palette.length];

  static void open(BuildContext context, Attraction attraction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => attraction.hasFloorPlan
            ? FloorPlanScreen(attraction: attraction)
            : AttractionMapScreen(attraction: attraction),
      ),
    );
  }

  /// Khu vực chứa vùng beacon khách đang đứng, nếu có.
  static String? hereAttractionId() {
    final zone = BeaconScanController.instance.currentZone;
    if (zone == null) return null;
    for (final a in ArtifactRepository.instance.artifacts) {
      if (zone.artifactIds.contains(a.id) && a.attractionId != null) {
        return a.attractionId;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArtifactRepository.instance,
        BeaconScanController.instance,
      ]),
      builder: (context, _) {
        final attractions = [
          for (final a in ArtifactRepository.instance.attractions)
            if (a.floorId == floor.id) a,
        ];
        final hereId = hereAttractionId();
        final plan = floor.floorPlanUrl;
        final onMap = [
          for (final a in attractions)
            if (a.mapBlock != null) a,
        ];

        final Widget view;
        if (plan != null) {
          view = _PlanView(
            url: plan,
            attractions: attractions,
            hereId: hereId,
            onOpen: (a) => open(context, a),
          );
        } else if (onMap.isNotEmpty) {
          view = HeritageMap(
            pins: const [],
            initialFit: [
              for (final a in onMap)
                for (final (lng, lat) in a.mapBlock!) (lat, lng),
            ],
            maxFitZoom: 19,
            blocks: [
              for (var i = 0; i < onMap.length; i++)
                MapBlock(
                  id: 'block:${onMap[i].id}',
                  label: onMap[i].name,
                  points: [
                    for (final (lng, lat) in onMap[i].mapBlock!) (lat, lng),
                  ],
                  color: onMap[i].id == hereId
                      ? AppColors.accent
                      // Cùng màu với nút của nó ở dải dưới.
                      : colorAt(attractions.indexOf(onMap[i])),
                  onTap: () => open(context, onMap[i]),
                ),
            ],
          );
        } else {
          view = MapMessage(
            icon: Icons.layers_outlined,
            title: context.l10n.mapFloorNoPlan,
            text: context.l10n.mapPickAreaBelow,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(floor.name, overflow: TextOverflow.ellipsis),
          ),
          body: Column(
            children: [
              Expanded(child: view),
              _AttractionStrip(
                attractions: attractions,
                hereId: hereId,
                onOpen: (a) => open(context, a),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ảnh sơ đồ tầng + khối khu vực. Phải biết tỉ lệ ảnh thật trước khi vẽ khối,
/// không thì khối lệch khi ảnh co giãn (giống [FloorPlanScreen]).
class _PlanView extends StatefulWidget {
  const _PlanView({
    required this.url,
    required this.attractions,
    required this.hereId,
    required this.onOpen,
  });

  final String url;
  final List<Attraction> attractions;
  final String? hereId;
  final ValueChanged<Attraction> onOpen;

  @override
  State<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<_PlanView> {
  double? _ratio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _stream = NetworkImage(widget.url).resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(() => _ratio = info.image.width / info.image.height);
        }
      },
      onError: (_, _) {
        if (mounted) setState(() => _ratio = -1);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  /// Khối vẽ được trên sơ đồ, kèm màu cố định theo thứ tự khu vực trên tầng.
  List<(Attraction, Color)> get _blocks => [
    for (var i = 0; i < widget.attractions.length; i++)
      if (widget.attractions[i].planBlock != null)
        (
          widget.attractions[i],
          widget.attractions[i].id == widget.hereId
              ? AppColors.accent
              : FloorScreen.colorAt(i),
        ),
  ];

  /// Khối chứa điểm chạm (x, y theo tỉ lệ 0..1); khối vẽ sau nằm trên.
  Attraction? _hit(double x, double y) {
    for (final (a, _) in _blocks.reversed) {
      if (_contains(a.planBlock!, x, y)) return a;
    }
    return null;
  }

  /// Ray casting: điểm nằm trong đa giác khi tia ngang cắt cạnh số lẻ lần.
  static bool _contains(List<(double, double)> poly, double x, double y) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final (xi, yi) = poly[i];
      final (xj, yj) = poly[j];
      if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio;
    if (ratio == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ratio <= 0) {
      return MapMessage(
        icon: Icons.broken_image_outlined,
        title: context.l10n.mapFloorPlanLoadFailed,
        text: context.l10n.mapPickAreaBelow,
      );
    }
    final blocks = _blocks;
    return ColoredBox(
      color: AppColors.surfaceTint,
      child: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: AspectRatio(
            aspectRatio: ratio,
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                onTapUp: (details) {
                  final p = details.localPosition;
                  final hit = _hit(p.dx / box.maxWidth, p.dy / box.maxHeight);
                  if (hit != null) widget.onOpen(hit);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(widget.url, fit: BoxFit.fill),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _BlocksPainter(blocks)),
                    ),
                    for (final (a, color) in blocks)
                      _BlockLabel(
                        attraction: a,
                        color: color,
                        size: box.biggest,
                        isHere: a.id == widget.hereId,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlocksPainter extends CustomPainter {
  _BlocksPainter(this.blocks);

  final List<(Attraction, Color)> blocks;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (a, color) in blocks) {
      final points = a.planBlock!;
      final path = Path()
        ..addPolygon([
          for (final (x, y) in points) Offset(x * size.width, y * size.height),
        ], true);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.28));
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_BlocksPainter old) => old.blocks != blocks;
}

/// Tên khu vực đặt ở trọng tâm khối.
class _BlockLabel extends StatelessWidget {
  const _BlockLabel({
    required this.attraction,
    required this.color,
    required this.size,
    required this.isHere,
  });

  final Attraction attraction;
  final Color color;
  final Size size;
  final bool isHere;

  @override
  Widget build(BuildContext context) {
    final points = attraction.planBlock!;
    final cx = points.map((p) => p.$1).reduce((a, b) => a + b) / points.length;
    final cy = points.map((p) => p.$2).reduce((a, b) => a + b) / points.length;
    return Positioned(
      left: cx * size.width,
      top: cy * size.height,
      // Chạm vào nhãn cũng là chạm vào khối — để cử chỉ lọt xuống lớp dưới.
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHere) ...[
                  const Icon(
                    Icons.bluetooth_searching,
                    size: 13,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  attraction.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color.lerp(color, Colors.black, 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dải nút khu vực của tầng ở đáy màn — lối vào cho cả khu vực chưa vẽ khối.
class _AttractionStrip extends StatelessWidget {
  const _AttractionStrip({
    required this.attractions,
    required this.hereId,
    required this.onOpen,
  });

  final List<Attraction> attractions;
  final String? hereId;
  final ValueChanged<Attraction> onOpen;

  @override
  Widget build(BuildContext context) {
    if (attractions.isEmpty) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.mapFloorNoAreas,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: attractions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final a = attractions[i];
              final here = a.id == hereId;
              return ActionChip(
                avatar: Icon(
                  here
                      ? Icons.bluetooth_searching
                      : (a.hasFloorPlan
                            ? Icons.apartment_outlined
                            : Icons.map_outlined),
                  size: 18,
                  color: here ? AppColors.accent : FloorScreen.colorAt(i),
                ),
                label: Text(a.name),
                side: BorderSide(
                  color: here ? AppColors.accent : AppColors.divider,
                ),
                backgroundColor: Colors.white,
                onPressed: () => onOpen(a),
              );
            },
          ),
        ),
      ),
    );
  }
}
