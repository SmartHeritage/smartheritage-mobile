import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../screens/artifact/artifact_detail_screen.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';

/// Ảnh đại diện hiện vật (placeholder gradient + icon).
class ArtifactThumb extends StatelessWidget {
  const ArtifactThumb({
    super.key,
    required this.artifact,
    this.size = 64,
    this.radius = 16,
    this.iconSize,
  });

  final Artifact artifact;
  final double size;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final asset = artifact.imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: artifact.imageAlignment,
          errorBuilder: (context, error, stack) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: artifact.gradient,
        ),
      ),
      child: Icon(artifact.icon, color: Colors.white, size: iconSize ?? size * 0.45),
    );
  }
}

/// Ảnh hiện vật khổ lớn (dùng cho card ngang màn hình).
///
/// Hiển thị [Artifact.imageUrl] khi có; nếu chưa có ảnh thật thì dùng
/// placeholder gradient + icon (sẽ "up ảnh sau").
class ArtifactImage extends StatelessWidget {
  const ArtifactImage({
    super.key,
    required this.artifact,
    this.height = 190,
  });

  final Artifact artifact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = artifact.imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: artifact.imageAlignment,
        errorBuilder: (context, error, stack) => _placeholder(),
      );
    }
    final url = artifact.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: artifact.gradient,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(artifact.icon, color: Colors.white, size: 60),
          const SizedBox(height: 8),
          Text(
            'Ảnh cập nhật sau',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút yêu thích đồng bộ với [FavoriteStore].
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.artifactId,
    this.color,
  });

  final String artifactId;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoriteStore.ids,
      builder: (context, ids, _) {
        final isFav = ids.contains(artifactId);
        return IconButton(
          onPressed: () async {
            // Yêu thích là dữ liệu theo dõi → yêu cầu đăng nhập.
            final ok = await AuthController.ensureLoggedIn(context);
            if (!ok || !context.mounted) return;
            final wasFav = FavoriteStore.isFavorite(artifactId);
            FavoriteStore.toggle(artifactId);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(wasFav
                    ? 'Đã xoá khỏi danh sách yêu thích'
                    : 'Đã lưu vào danh sách yêu thích'),
                duration: const Duration(seconds: 1),
              ));
          },
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppColors.danger : (color ?? AppColors.textSecondary),
          ),
        );
      },
    );
  }
}

/// Thẻ hiện vật dạng danh sách (dùng ở Trang chủ, Yêu thích...).
class ArtifactListTile extends StatelessWidget {
  const ArtifactListTile({
    super.key,
    required this.artifact,
    this.trailing,
    this.subtitle,
  });

  final Artifact artifact;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ArtifactDetailScreen(artifact: artifact),
      )),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ArtifactThumb(artifact: artifact),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle ?? artifact.era,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 3),
                      Text(
                        '${artifact.rating}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.place_outlined,
                          size: 15, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        artifact.zone,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing ?? FavoriteButton(artifactId: artifact.id),
          ],
        ),
      ),
    );
  }
}

/// Hiệu ứng radar lan toả cho trạng thái quét beacon.
class RadarPulse extends StatefulWidget {
  const RadarPulse({super.key, this.size = 120, this.color = AppColors.accent});

  final double size;
  final Color color;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final delay in [0.0, 0.5])
                _ring((_controller.value + delay) % 1.0),
              Container(
                width: widget.size * 0.38,
                height: widget.size * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(Icons.bluetooth_searching,
                    color: Colors.white, size: 26),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t) {
    return Container(
      width: widget.size * (0.4 + 0.6 * t),
      height: widget.size * (0.4 + 0.6 * t),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: (1 - t) * 0.6),
          width: 2,
        ),
      ),
    );
  }
}

/// Tiêu đề khu vực có nút "Xem tất cả".
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
      ],
    );
  }
}
