import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../l10n/l10n.dart';
import '../../state/audio_player_state.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';

/// Tab "Danh sách nghe": mọi hiện vật có thuyết minh, nghe lần lượt như một
/// playlist — hết bài tự sang bài kế ([AudioPlayerController.playQueue]).
///
/// Thay chỗ tab Bản đồ trên thanh điều hướng (2026-10-21); bản đồ giờ mở từ ô
/// Bản đồ ở trang chủ V2.
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ArtifactRepository.instance;
    final player = AudioPlayerController.instance;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.playlistTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([repo, player]),
        builder: (context, _) {
          // Chỉ bài có file thật: bài câm mà nằm trong danh sách thì bấm vào
          // chỉ ra dòng "chưa có thuyết minh", tự chuyển bài cũng phải nhảy qua.
          final tracks = [
            for (final a in repo.artifacts)
              if (a.hasAudio) a,
          ];
          if (tracks.isEmpty) {
            if (repo.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _EmptyState(onRefresh: repo.refresh);
          }

          final current = player.artifact;
          // Đang nghe đúng danh sách này (không phải một bài lẻ mở từ trang
          // chi tiết) thì nút đầu trang thành tạm dừng/tiếp tục.
          final playingList =
              current != null &&
              player.queue.isNotEmpty &&
              tracks.any((a) => a.id == current.id);

          return RefreshIndicator(
            onRefresh: repo.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: tracks.length + 1,
              separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 16 : 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _Header(
                    count: tracks.length,
                    playing: playingList && player.isPlaying,
                    onPressed: playingList
                        ? player.togglePlay
                        : () => _listen(
                            context,
                            () => player.playQueue(tracks, 0),
                          ),
                  );
                }
                final track = tracks[i - 1];
                final isCurrent = current?.id == track.id;
                return _TrackTile(
                  artifact: track,
                  isCurrent: isCurrent,
                  isPlaying: isCurrent && player.isPlaying,
                  isLoading: isCurrent && player.isLoading,
                  onTap: isCurrent && player.error == null
                      ? player.togglePlay
                      : () => _listen(
                          context,
                          () => player.playQueue(tracks, i - 1),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Nghe thuyết minh phải đăng nhập (2026-10-21). Khách vẫn xem được danh sách,
/// bấm nghe mới hỏi; đăng nhập xong thì phát luôn bài vừa chọn.
Future<void> _listen(BuildContext context, VoidCallback play) async {
  if (await AuthController.ensureLoggedIn(context)) play();
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.playing,
    required this.onPressed,
  });

  final int count;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.playlistSummary(count),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          label: Text(context.l10n.playlistPlayAll),
        ),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.artifact,
    required this.isCurrent,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final Artifact artifact;
  final bool isCurrent;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget indicator;
    if (isLoading) {
      indicator = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      );
    } else {
      indicator = Icon(
        // Bài đang nghe hiện sóng âm thay số thứ tự như app nhạc; tạm dừng
        // thì về nút phát để biết bấm vào là nghe tiếp.
        isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
        color: isCurrent ? AppColors.primary : AppColors.textSecondary,
        size: 26,
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.surfaceTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? AppColors.primaryLight : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            ArtifactThumb(artifact: artifact, size: 52, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artifact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artifact.zone} · ${artifact.audioDuration}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            indicator,
            IconButton(
              tooltip: context.l10n.audioViewArtifact,
              onPressed: () => openArtifactDetail(context, artifact),
              icon: const Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    // Vẫn kéo xuống để tải lại được: admin vừa tải audio lên thì khỏi phải
    // mở lại app.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.queue_music_rounded,
                        size: 44,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.l10n.playlistEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
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
