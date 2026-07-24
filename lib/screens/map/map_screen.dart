import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';

/// Bản đồ khu di tích (minh hoạ) với các điểm hiện vật.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Artifact? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ tham quan'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.layers_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _zoneChip('Tất cả', selected: true),
                  _zoneChip('Khu trưng bày A'),
                  _zoneChip('Khu trưng bày B'),
                  _zoneChip('Khu trưng bày C'),
                  _zoneChip('Sân ngoài trời'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Nền bản đồ minh hoạ
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapBackgroundPainter(),
                          ),
                        ),
                        // Vị trí hiện tại của khách
                        Positioned(
                          left: constraints.maxWidth * 0.48 - 40,
                          top: constraints.maxHeight * 0.45 - 40,
                          child: const RadarPulse(size: 80),
                        ),
                        // Các điểm hiện vật
                        for (final artifact in MockData.artifacts)
                          Positioned(
                            left: constraints.maxWidth * artifact.mapX - 22,
                            top: constraints.maxHeight * artifact.mapY - 44,
                            child: _MapPin(
                              artifact: artifact,
                              selected: _selected?.id == artifact.id,
                              onTap: () =>
                                  setState(() => _selected = artifact),
                            ),
                          ),
                        // Thẻ thông tin hiện vật được chọn
                        if (_selected != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: _MapArtifactCard(
                              artifact: _selected!,
                              onClose: () =>
                                  setState(() => _selected = null),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneChip(String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 48 : 44,
            height: selected ? 48 : 44,
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
          Container(
            width: 3,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapArtifactCard extends StatelessWidget {
  const _MapArtifactCard({required this.artifact, required this.onClose});

  final Artifact artifact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                      '${artifact.zone} · cách bạn ~35m',
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
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(
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

/// Vẽ nền bản đồ minh hoạ: nền xanh nhạt, lối đi, khu trưng bày.
class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.surfaceTint;
    canvas.drawRect(Offset.zero & size, bg);

    // Các khu trưng bày (khối nhạt)
    final block = Paint()..color = const Color(0xFFEADBCF);
    final blocks = [
      Rect.fromLTWH(size.width * 0.08, size.height * 0.10, size.width * 0.34,
          size.height * 0.28),
      Rect.fromLTWH(size.width * 0.55, size.height * 0.08, size.width * 0.36,
          size.height * 0.22),
      Rect.fromLTWH(size.width * 0.12, size.height * 0.52, size.width * 0.30,
          size.height * 0.26),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.44, size.width * 0.32,
          size.height * 0.24),
    ];
    for (final rect in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        block,
      );
    }

    // Lối đi
    final path = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final walkway = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..lineTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.26, size.height * 0.32)
      ..moveTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.66, size.height * 0.24)
      ..moveTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.36, size.height * 0.62)
      ..moveTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.74, size.height * 0.56);
    canvas.drawPath(walkway, path);

    // Cây xanh trang trí
    final tree = Paint()..color = const Color(0xFFB7D8C3);
    final treeSpots = [
      Offset(size.width * 0.90, size.height * 0.86),
      Offset(size.width * 0.10, size.height * 0.90),
      Offset(size.width * 0.88, size.height * 0.36),
      Offset(size.width * 0.06, size.height * 0.44),
    ];
    for (final spot in treeSpots) {
      canvas.drawCircle(spot, 14, tree);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
