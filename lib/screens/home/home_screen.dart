import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../state/audio_player_state.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';
import '../history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _beaconTimer;
  bool _sheetShown = false;
  bool _scanning = false; // tính năng quét iBeacon đang bật hay tắt

  @override
  void dispose() {
    _beaconTimer?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() => _scanning = true);
    // Mô phỏng: khi đang quét, sau vài giây beacon phát hiện một hiện vật.
    _beaconTimer?.cancel();
    _beaconTimer = Timer(const Duration(seconds: 4), _showBeaconSheet);
  }

  void _stopScan() {
    _beaconTimer?.cancel();
    setState(() => _scanning = false);
  }

  void _showBeaconSheet() {
    if (!mounted || !_scanning || _sheetShown) return;
    _sheetShown = true;
    final artifact = MockData.artifacts[1];
    // iBeacon phát hiện → ghi vào lịch sử tham quan (lưu local, kể cả khách).
    VisitHistoryController.instance.recordBeaconVisit(artifact);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => BeaconDetectedSheet(artifact: artifact),
    ).whenComplete(() => _sheetShown = false);
  }

  @override
  Widget build(BuildContext context) {
    final artifacts = MockData.artifacts;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildBeaconBanner(),
            const SizedBox(height: 24),
            // "Tham quan gần đây" là dữ liệu theo dõi → chỉ hiện khi đã đăng nhập,
            // và đặt trên "Hiện vật nổi bật".
            _buildRecentVisits(),
            SectionHeader(title: 'Hiện vật nổi bật', onSeeAll: () {}),
            const SizedBox(height: 12),
            for (final artifact in artifacts) ...[
              _FeaturedCard(artifact: artifact),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  /// Mục "Tham quan gần đây" — lưu local, hiện cho cả khách; chỉ gồm các hiện
  /// vật do iBeacon phát hiện. Ẩn khi chưa có lần phát hiện nào.
  Widget _buildRecentVisits() {
    return ListenableBuilder(
      listenable: VisitHistoryController.instance,
      builder: (context, _) {
        final records = VisitHistoryController.instance.records;
        if (records.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Tham quan gần đây',
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            for (final record in records.take(3)) ...[
              ArtifactListTile(
                artifact: record.artifact,
                subtitle: '${record.dateLabel} · ${record.timeLabel}',
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Khám phá di sản',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Khám phá di sản quanh bạn hôm nay',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm hiện vật, khu trưng bày...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.tune, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Một card duy nhất cho cả hai trạng thái. Khi đang quét: nền đổi sang nâu
  /// đỏ chủ đạo, icon toả sóng, chữ và nút đổi tương ứng.
  Widget _buildBeaconBanner() {
    final scanning = _scanning;
    final titleColor = scanning ? Colors.white : AppColors.textPrimary;
    final subtitleColor =
        scanning ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(scanning ? 26 : 16, 16, 16, 16),
      decoration: BoxDecoration(
        color: scanning ? AppColors.primary : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(22),
        border: scanning ? null : Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Ô icon: khi tắt là bluetooth mờ; khi bật là bluetooth toả sóng.
          SizedBox(
            width: 56,
            height: 56,
            child: scanning
                ? const _ScanningPulseIcon(size: 56)
                : Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bluetooth_disabled,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                  ),
          ),
          SizedBox(width: scanning ? 26 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanning ? 'Đang quét iBeacon' : 'Quét iBeacon đang tắt',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scanning
                      ? 'Đang tìm hiện vật ở gần bạn…'
                      : 'Bật để tự động phát hiện hiện vật ở gần bạn',
                  maxLines: scanning ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: scanning ? _stopScan : _startScan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: scanning ? Colors.white : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          scanning
                              ? Icons.power_settings_new
                              : Icons.bluetooth_searching,
                          size: 17,
                          color: scanning ? AppColors.primary : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          scanning ? 'Tắt quét' : 'Bật quét iBeacon',
                          style: TextStyle(
                            color: scanning ? AppColors.primary : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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

/// Icon khi đang quét: cùng kiểu vòng tròn trắng như mode tắt (nhưng bluetooth
/// bật, màu chủ đạo) + các vòng sóng radar lan ra để báo đang quét.
class _ScanningPulseIcon extends StatefulWidget {
  const _ScanningPulseIcon({this.size = 56});

  final double size;

  @override
  State<_ScanningPulseIcon> createState() => _ScanningPulseIconState();
}

class _ScanningPulseIconState extends State<_ScanningPulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // Vùng vẽ rộng hơn ô để sóng có chỗ lan ra (OverflowBox bỏ ràng buộc 56px).
    final canvas = size * 1.7;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: OverflowBox(
          maxWidth: canvas,
          maxHeight: canvas,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (final delay in [0.0, 0.33, 0.66])
                    _ring((_controller.value + delay) % 1.0, size),
                  child!,
                ],
              );
            },
            // Vòng tròn trắng + icon bluetooth bật (giữ giống mode tắt).
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double t, double size) {
    // Lan từ mép vòng tròn (size) ra ngoài ~1.65x, mờ dần.
    final diameter = size * (1.0 + 0.65 * t);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: (1 - t) * 0.7),
          width: 2.5,
        ),
      ),
    );
  }
}

/// Bottom sheet hiện ra khi beacon phát hiện khách đến gần hiện vật.
class BeaconDetectedSheet extends StatelessWidget {
  const BeaconDetectedSheet({super.key, required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.bluetooth_connected,
                  size: 16,
                  color: AppColors.accent,
                ),
                SizedBox(width: 6),
                Text(
                  'Phát hiện qua iBeacon · cách bạn ~2m',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ArtifactThumb(artifact: artifact, size: 92, radius: 24),
          const SizedBox(height: 14),
          Text(
            artifact.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artifact.era,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artifact.shortIntro,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                AudioPlayerController.instance.play(artifact);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 6),
                    Text(
                      'Nghe thuyết minh âm thanh',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Để sau'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ArtifactDetailScreen(artifact: artifact),
                      ),
                    );
                  },
                  child: const Text('Khám phá ngay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card hiện vật khổ ngang màn hình: ảnh lớn + tên + chú thích + đánh giá.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArtifactDetailScreen(artifact: artifact),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh khổ ngang (placeholder khi chưa up ảnh thật)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  ArtifactImage(artifact: artifact, height: 190),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${artifact.rating}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${artifact.reviewCount})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: FavoriteButton(artifactId: artifact.id),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artifact.zone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artifact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artifact.era,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artifact.shortIntro,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
