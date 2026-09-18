import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../state/audio_player_state.dart';
import '../../state/beacon_scan_state.dart';
import '../../state/notification_state.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';
import '../history/history_screen.dart';
import '../notification/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scan = BeaconScanController.instance;
  final _searchController = TextEditingController();
  bool _sheetShown = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scan.addListener(_onScanChanged);
  }

  @override
  void dispose() {
    _scan.removeListener(_onScanChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Lọc theo tên, thời kỳ và khu trưng bày.
  List<Artifact> get _results {
    final all = ArtifactRepository.instance.artifacts;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((a) {
      return a.name.toLowerCase().contains(q) ||
          a.era.toLowerCase().contains(q) ||
          a.zone.toLowerCase().contains(q);
    }).toList();
  }

  /// Công tắc quét nằm ở sidebar, nhưng phần mở sheet giới thiệu vẫn thuộc
  /// trang chủ vì cần BuildContext của nó.
  void _onScanChanged() {
    final artifact = _scan.detected;
    if (artifact == null || _sheetShown || !mounted) return;
    _scan.consumeDetection();
    // Phát thuyết minh ngay khi beacon phát hiện — khách không phải bấm gì.
    // Nếu đang tắt tiếng thì vẫn chạy tiến trình, chỉ im lặng.
    AudioPlayerController.instance.play(artifact);
    _showBeaconSheet(artifact);
  }

  void _showBeaconSheet(Artifact artifact) {
    _sheetShown = true;
    // Sheet là một route nên nó phủ LÊN sidebar đang mở chứ không tắt sidebar.
    // Đóng drawer trước, không thì đóng sheet xong vẫn thấy sidebar còn đó.
    // HomeScreen không bọc Scaffold riêng nên đây là Scaffold của MainShell.
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
    // iBeacon phát hiện → ghi vào lịch sử tham quan (lưu local, kể cả khách).
    VisitHistoryController.instance.recordBeaconVisit(artifact);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => BeaconDetectedSheet(artifact: artifact),
    ).whenComplete(() => _sheetShown = false);
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách hiện vật đến từ API nên phải vẽ lại khi repository tải xong.
    return ListenableBuilder(
      listenable: ArtifactRepository.instance,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final results = _results;
    // Không bọc Scaffold riêng: dùng Scaffold của MainShell để nút menu ở
    // header mở được sidebar qua Scaffold.of(context).
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: ArtifactRepository.instance.refresh,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(context),
          if (ArtifactRepository.instance.isOffline) ...[
            const SizedBox(height: 12),
            _buildOfflineBanner(),
          ],
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 24),
          // Đang tìm kiếm thì ẩn "Tham quan gần đây" để kết quả lên trên cùng.
          if (!searching) ...[
            // Dữ liệu theo dõi → lưu local, đặt trên "Hiện vật nổi bật".
            _buildRecentVisits(),
            const SectionHeader(title: 'Hiện vật nổi bật'),
          ] else
            SectionHeader(title: 'Kết quả tìm kiếm (${results.length})'),
          const SizedBox(height: 12),
          if (searching && results.isEmpty)
            _buildNoResults()
          else
            for (final artifact in results) ...[
              _FeaturedCard(artifact: artifact),
              const SizedBox(height: 16),
            ],
        ],
        ),
      ),
    );
  }

  /// Báo cho khách biết đang xem dữ liệu đóng gói sẵn, không phải dữ liệu mới
  /// nhất — kéo xuống để thử tải lại.
  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Chưa kết nối được máy chủ — đang xem dữ liệu sẵn có.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: ArtifactRepository.instance.refresh,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Thử lại', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off,
                size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy hiện vật',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Không có kết quả nào cho "${_query.trim()}".\n'
            'Thử tên hiện vật, thời kỳ hoặc khu trưng bày.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: 46,
            height: 46,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu, color: AppColors.primary),
          ),
        ),
        const Expanded(
          child: Text(
            'Khám phá di sản',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _buildNotificationButton(context),
      ],
    );
  }

  /// Nút chuông: badge đỏ chỉ hiện khi còn thông báo chưa đọc.
  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
      child: ListenableBuilder(
        listenable: NotificationController.instance,
        builder: (context, _) {
          final unread = NotificationController.instance.unreadCount;
          return Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm hiện vật, khu trưng bày...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.textSecondary,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
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
    // Cuộn được: nội dung sheet sát giới hạn chiều cao của showModalBottomSheet,
    // máy màn hình ngắn hoặc cỡ chữ hệ thống lớn là tràn.
    return SingleChildScrollView(
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
              borderRadius: BorderRadius.circular(12),
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
          // Thuyết minh đã tự phát khi beacon phát hiện; ở đây chỉ báo trạng
          // thái và cho khách tắt/bật tiếng.
          const _BeaconAudioStatus(),
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

/// Dải trạng thái thuyết minh trong sheet beacon: báo đang phát hay đã tắt
/// tiếng, kèm nút loa để khách tự quyết.
class _BeaconAudioStatus extends StatelessWidget {
  const _BeaconAudioStatus();

  @override
  Widget build(BuildContext context) {
    final controller = AudioPlayerController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final muted = controller.isMuted;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            gradient: muted
                ? null
                : const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
            color: muted ? AppColors.surfaceTint : null,
            borderRadius: BorderRadius.circular(10),
            border: muted ? Border.all(color: AppColors.divider) : null,
          ),
          child: Row(
            children: [
              Icon(
                muted ? Icons.volume_off_rounded : Icons.graphic_eq_rounded,
                color: muted ? AppColors.textSecondary : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  muted
                      ? 'Thuyết minh đang tắt tiếng'
                      : 'Đang phát thuyết minh âm thanh',
                  style: TextStyle(
                    color: muted ? AppColors.textPrimary : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.toggleMute,
                style: TextButton.styleFrom(
                  foregroundColor: muted ? AppColors.primary : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(muted ? 'Bật tiếng' : 'Tắt tiếng'),
              ),
            ],
          ),
        );
      },
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
          borderRadius: BorderRadius.circular(14),
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
                  const BorderRadius.vertical(top: Radius.circular(14)),
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
                        borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
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
