import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../audio/audio_player_screen.dart';
import '../feedback/feedback_screen.dart';

class ArtifactDetailScreen extends StatefulWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.artifact,
    this.initialTabIndex = 0,
  });

  final Artifact artifact;
  final int initialTabIndex;

  @override
  State<ArtifactDetailScreen> createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends State<ArtifactDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.initialTabIndex,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.artifact;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: artifact.gradient.first,
            foregroundColor: Colors.white,
            leading: _circleButton(
              context,
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: FavoriteButton(artifactId: artifact.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _heroBackground(artifact),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildTitleBlock(artifact),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Giới thiệu'),
                Tab(text: 'Hình ảnh'),
                Tab(text: 'Video'),
                Tab(text: 'Đánh giá'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _IntroTab(artifact: artifact),
                  _GalleryTab(artifact: artifact),
                  _VideoTab(artifact: artifact),
                  FeedbackForm(artifact: artifact),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nền hero: ưu tiên ảnh chi tiết → ảnh thường → gradient + icon.
  Widget _heroBackground(Artifact artifact) {
    final image = artifact.detailImageAsset ?? artifact.imageAsset;
    if (image != null && image.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: artifact.detailImageAlignment,
          ),
          // Lớp phủ tối nhẹ ở trên/dưới để nút và tiêu đề dễ nhìn.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.20),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: artifact.gradient,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Icon(
            artifact.icon,
            size: 110,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _circleButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildTitleBlock(Artifact artifact) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  artifact.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 3),
              Text(
                '${artifact.rating} (${artifact.reviewCount})',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.history_edu_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  artifact.era,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.place_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  artifact.zone,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroTab extends StatelessWidget {
  const _IntroTab({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Nhắc người dùng: nội dung vẫn xem được ngoài vùng beacon.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Icon(Icons.offline_pin_outlined,
                  color: AppColors.accent, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nội dung đã được lưu — bạn có thể tiếp tục xem kể cả khi rời khỏi vùng phủ sóng beacon.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryLight,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Giới thiệu chung',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          artifact.description,
          style: const TextStyle(
            fontSize: 15,
            height: 1.65,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          artifact.description,
          style: const TextStyle(
            fontSize: 15,
            height: 1.65,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        // Thuyết minh có màn hình riêng (kiểu now-playing) chứ không còn là tab.
        FilledButton.icon(
          onPressed: () => Navigator.of(context)
              .push(AudioPlayerScreen.route(artifact)),
          icon: const Icon(Icons.headphones_rounded, size: 20),
          label: const Text('Nghe thuyết minh âm thanh'),
        ),
      ],
    );
  }
}

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                artifact.gradient.first
                    .withValues(alpha: 1 - (i % 3) * 0.18),
                artifact.gradient.last,
              ],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  i.isEven ? artifact.icon : Icons.photo_outlined,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 44,
                ),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                child: Text(
                  'Ảnh ${i + 1}/6',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoTab extends StatelessWidget {
  const _VideoTab({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        for (var i = 0; i < 2; i++) ...[
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: artifact.gradient,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 38, color: AppColors.primary),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      artifact.videoDuration,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            i == 0
                ? 'Thuyết minh: ${artifact.name}'
                : 'Phim tư liệu: quá trình phát hiện và bảo tồn',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Video có phụ đề tiếng Việt và tiếng Anh',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
