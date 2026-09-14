import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mock_data.dart';
import '../../state/audio_player_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';
import '../profile/language_screen.dart';

/// Màn hình nghe thuyết minh, kiểu now-playing: nền gradient tối lấy từ màu
/// của hiện vật, artwork lớn, và card nội dung hé ở dưới.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key, required this.artifact});

  final Artifact artifact;

  /// Trượt từ dưới lên khi mở. Pop tự chạy transition ngược nên nút mũi tên
  /// xuống (và swipe back) trượt xuống, giống now-playing của app nhạc.
  static Route<void> route(Artifact artifact) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) =>
          AudioPlayerScreen(artifact: artifact),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _controller = AudioPlayerController.instance;

  @override
  void initState() {
    super.initState();
    // Hoãn sang sau frame: play() gọi notifyListeners() và MiniPlayerBar đang
    // lắng nghe, gọi thẳng trong initState sẽ markNeedsBuild giữa lúc build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.artifact?.id != widget.artifact.id) {
        _controller.play(widget.artifact);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.artifact;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _backdrop(artifact)),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              // Progress của controller là chung; nếu đang phát hiện vật khác
              // thì màn này hiện 0 thay vì tiến trình của bài kia.
              final active = _controller.artifact?.id == artifact.id;
              final progress = active ? _controller.progress : 0.0;
              return Column(
                children: [
                  _topBar(context, artifact),
                  // Artwork co theo chỗ còn lại nên không bao giờ tràn, kể cả
                  // máy màn hình ngắn.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, constraints) => _artwork(
                              artifact,
                              constraints.biggest.shortestSide,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _titleRow(artifact),
                  const SizedBox(height: 10),
                  _progressBar(artifact, progress, active),
                  const SizedBox(height: 4),
                  _controls(artifact, active),
                  const SizedBox(height: 6),
                  _secondaryRow(context, artifact),
                  const SizedBox(height: 10),
                  _contentCard(context, artifact),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Nền tối dần xuống dưới, pha từ chính gradient của hiện vật.
  LinearGradient _backdrop(Artifact artifact) {
    final top = artifact.gradient.first;
    final mid = artifact.gradient.last;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(top, Colors.black, 0.22)!,
        Color.lerp(mid, Colors.black, 0.45)!,
        Color.lerp(top, Colors.black, 0.80)!,
      ],
      stops: const [0, 0.42, 1],
    );
  }

  Widget _topBar(BuildContext context, Artifact artifact) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 30),
        ),
        const Expanded(
          child: Text(
            'Thuyết minh âm thanh',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ArtifactDetailScreen(artifact: artifact),
          )),
          tooltip: 'Xem chi tiết hiện vật',
          icon: const Icon(Icons.more_horiz, color: Colors.white),
        ),
      ],
    );
  }

  Widget _artwork(Artifact artifact, double side) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ArtifactThumb(artifact: artifact, size: side, radius: 14),
    );
  }

  Widget _titleRow(Artifact artifact) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artifact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${artifact.era} · ${artifact.zone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          FavoriteButton(artifactId: artifact.id, color: Colors.white),
        ],
      ),
    );
  }

  Widget _progressBar(Artifact artifact, double progress, bool active) {
    final total = _parseDuration(artifact.audioDuration);
    final elapsed = total * progress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
              thumbColor: Colors.white,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6.5),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: progress,
              onChanged: (v) {
                if (!active) _controller.play(artifact);
                _controller.seek(v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(elapsed), style: _timeStyle),
                Text('-${_format(total - elapsed)}', style: _timeStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(Artifact artifact, bool active) {
    final playing = active && _controller.isPlaying;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: _controller.toggleMute,
          tooltip: _controller.isMuted ? 'Bật tiếng' : 'Tắt tiếng',
          icon: Icon(
            _controller.isMuted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            // Đang tắt tiếng thì tô vàng kim cho nổi, giống cách Spotify
            // đánh dấu shuffle đang bật.
            color: _controller.isMuted
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.85),
            size: 26,
          ),
        ),
        IconButton(
          onPressed: () => _controller.seek(_controller.progress - 0.05),
          icon: const Icon(Icons.replay_10_rounded,
              color: Colors.white, size: 32),
        ),
        GestureDetector(
          onTap: () {
            if (!active) {
              _controller.play(artifact);
            } else {
              _controller.togglePlay();
            }
          },
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.primaryDark,
              size: 38,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _controller.seek(_controller.progress + 0.05),
          icon: const Icon(Icons.forward_10_rounded,
              color: Colors.white, size: 32),
        ),
        TextButton(
          onPressed: _controller.cycleSpeed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '${_trimSpeed(_controller.speed)}×',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _secondaryRow(BuildContext context, Artifact artifact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
            tooltip: 'Ngôn ngữ thuyết minh',
            icon: Icon(Icons.translate,
                color: Colors.white.withValues(alpha: 0.75), size: 22),
          ),
          IconButton(
            onPressed: () => _share(context, artifact),
            tooltip: 'Chia sẻ',
            icon: Icon(Icons.ios_share,
                color: Colors.white.withValues(alpha: 0.75), size: 22),
          ),
        ],
      ),
    );
  }

  /// Card nội dung thuyết minh hé ở dưới, bấm để đọc toàn văn.
  Widget _contentCard(BuildContext context, Artifact artifact) {
    return GestureDetector(
      onTap: () => _showTranscript(context, artifact),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nội dung thuyết minh',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white.withValues(alpha: 0.75), size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              artifact.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranscript(BuildContext context, Artifact artifact) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              artifact.name,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${artifact.era} · ${artifact.zone}',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              artifact.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.65,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, Artifact artifact) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(
        text: 'smartheritage://artifact/${artifact.id} — ${artifact.name}',
      ),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Đã sao chép liên kết hiện vật'),
      ));
  }

  static const _timeStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// 'mm:ss' → Duration. Trả về zero nếu chuỗi không đúng dạng.
  static Duration _parseDuration(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return Duration.zero;
    return Duration(
      minutes: int.tryParse(parts[0]) ?? 0,
      seconds: int.tryParse(parts[1]) ?? 0,
    );
  }

  static String _format(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final seconds = safe.inSeconds % 60;
    return '${safe.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 1.0 → '1', 1.25 → '1.25' (bỏ '.0' cho gọn).
  static String _trimSpeed(double speed) {
    return speed == speed.roundToDouble()
        ? speed.toStringAsFixed(0)
        : speed.toString();
  }
}
