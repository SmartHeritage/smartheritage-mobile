import 'package:flutter/material.dart';

import '../screens/artifact/artifact_detail_screen.dart';
import '../state/audio_player_state.dart';
import '../theme/app_theme.dart';
import 'artifact_widgets.dart';

/// Thanh phát audio nổi phía trên thanh điều hướng, luôn hiển thị xuyên suốt
/// các màn hình khi có audio đang phát — tương tự mini-player của Spotify.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AudioPlayerController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final artifact = controller.artifact;
        if (artifact == null) return const SizedBox.shrink();

        return SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArtifactDetailScreen(
                    artifact: artifact,
                    initialTabIndex: 3,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: controller.progress,
                    minHeight: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.mint),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        ArtifactThumb(artifact: artifact, size: 42, radius: 10),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                artifact.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Thuyết minh âm thanh',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: controller.togglePlay,
                          icon: Icon(
                            controller.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: controller.close,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
