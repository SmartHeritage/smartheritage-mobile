import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/attraction.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../artifact/artifact_detail_screen.dart';

/// Sơ đồ tầng của một điểm tham quan trong nhà (`GET /attractions/:id/map`).
///
/// Vị trí hiện vật và beacon là tỉ lệ 0..1 trên ảnh sơ đồ, nên phải biết tỉ lệ
/// khung ảnh thật trước khi đặt ghim — không thì ghim lệch khi ảnh co giãn.
class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key, required this.attraction});

  final Attraction attraction;

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  late Future<AttractionMap> _map;
  double? _aspectRatio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _map = ArtifactRepository.instance.fetchAttractionMap(widget.attraction.id);
    _map.then((m) => _resolveImage(m.attraction.floorPlanUrl), onError: (_) {});
  }

  void _resolveImage(String? url) {
    if (url == null || !mounted) return;
    _stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _aspectRatio = info.image.width / info.image.height);
      },
      onError: (_, _) {
        if (mounted) setState(() => _aspectRatio = -1);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.attraction.name)),
      body: FutureBuilder<AttractionMap>(
        future: _map,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _Message(
              text: error is ApiException
                  ? error.message
                  : 'Không tải được sơ đồ.',
              onRetry: () => setState(_load),
            );
          }
          final map = snapshot.data;
          final ratio = _aspectRatio;
          if (map == null || ratio == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final url = map.attraction.floorPlanUrl;
          if (url == null || ratio <= 0) {
            return const _Message(text: 'Điểm tham quan này chưa có sơ đồ tầng.');
          }
          return InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(url, fit: BoxFit.fill),
                      ),
                      for (final m in map.markers)
                        Positioned(
                          left: m.x * box.maxWidth - 18,
                          top: m.y * box.maxHeight - 18,
                          child: _MarkerDot(
                            marker: m,
                            onTap: m.artifact == null
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ArtifactDetailScreen(
                                            artifact: m.artifact!),
                                      ),
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.marker, this.onTap});

  final FloorPlanMarker marker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final beacon = marker.isBeacon;
    return Tooltip(
      message: marker.name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: beacon ? Colors.white : AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: beacon ? AppColors.accent : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            beacon ? Icons.bluetooth : Icons.museum_outlined,
            size: 18,
            color: beacon ? AppColors.accent : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
