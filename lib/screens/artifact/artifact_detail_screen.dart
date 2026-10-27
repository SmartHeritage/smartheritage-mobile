import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_state.dart';
import '../../state/language_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../../widgets/nested_tab_scroll.dart';
import '../../widgets/rich_text_content.dart';
import '../audio/audio_player_screen.dart';
import '../feedback/feedback_screen.dart';
import '../profile/language_screen.dart';

/// Mở trang chi tiết hiện vật. Mọi lối vào trang chi tiết đi qua đây vì khách
/// phải đăng nhập mới xem được (yêu cầu 2026-10-21) — kể cả quét QR/beacon.
/// Chỉ chặn ở app: `GET /artifacts/:id` của backend vẫn công khai.
///
/// [replace] thay route hiện tại (màn quét QR) thay vì chồng lên. Trả `false`
/// khi khách huỷ đăng nhập — không mở gì, khách đứng yên chỗ cũ.
Future<bool> openArtifactDetail(
  BuildContext context,
  Artifact artifact, {
  bool replace = false,
}) async {
  // Lấy navigator trước khi chờ: lối vào từ bottom sheet đã đóng sheet, context
  // của nó không còn dùng được sau khi đăng nhập xong.
  final navigator = Navigator.of(context);
  if (!await AuthController.ensureLoggedIn(context)) return false;
  final route = MaterialPageRoute<void>(
    builder: (_) => ArtifactDetailScreen(artifact: artifact),
  );
  if (replace) {
    navigator.pushReplacement(route);
  } else {
    navigator.push(route);
  }
  return true;
}

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
    // Theo bản mới nhất trong kho: đổi ngôn ngữ (vd. từ nút "Đổi ngôn ngữ" ngay trên
    // trang này) thì kho tải lại, trang hiện đúng nội dung thứ tiếng mới khi quay về.
    return ListenableBuilder(
      listenable: ArtifactRepository.instance,
      builder: (context, _) => _build(
        context,
        ArtifactRepository.instance.tryById(widget.artifact.id) ??
            widget.artifact,
      ),
    );
  }

  Widget _build(BuildContext context, Artifact artifact) {
    final tabBar = TabBar(
      controller: _tabController,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      tabs: [
        Tab(text: context.l10n.artifactTabIntro),
        Tab(text: context.l10n.artifactTabPhotos),
        Tab(text: context.l10n.artifactTabVideo),
        Tab(text: context.l10n.artifactTabReviews),
      ],
    );
    // Tên + niên đại/khu vực + thanh tab là phần đáy của SliverAppBar ghim: cuộn
    // xuống thì chỉ ảnh hero co lại, khối này luôn nằm ngay dưới thanh trên. (Để ở
    // thân NestedScrollView như trước thì tên trôi mất, tab bị thanh trên che nửa.)
    final stickyHeight =
        _titleBlockHeight(context, artifact) + tabBar.preferredSize.height;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              expandedHeight: 260 + stickyHeight,
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
                  child: FavoriteButton(artifact: artifact),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                // Ảnh phủ phần trên, lấn xuống sau khối tên + tab đúng bằng độ bo
                // góc — để hai góc bo trên của khối lộ ảnh chứ không lộ nền.
                background: Padding(
                  padding: EdgeInsets.only(
                    bottom: stickyHeight - _headerRadius,
                  ),
                  child: _heroBackground(artifact),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(stickyHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_headerRadius),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_buildTitleBlock(artifact), tabBar],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _IntroTab(artifact: artifact),
            _GalleryTab(artifact: artifact),
            _VideoTab(artifact: artifact),
            ArtifactReviewsTab(artifact: artifact),
          ],
        ),
      ),
    );
  }

  /// Bo hai góc trên của khối tên + tab ghim, như tấm thẻ trượt lên trên ảnh.
  static const double _headerRadius = 22;

  static const _nameStyle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const _ratingStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const _metaStyle = TextStyle(
    fontSize: 13.5,
    color: AppColors.textSecondary,
  );

  /// Chiều cao khối tên ([_buildTitleBlock]) — phần đáy của SliverAppBar phải có
  /// chiều cao cố định, mà tên dài thì xuống hai dòng, cỡ chữ theo cài đặt máy.
  /// Đo bằng đúng kiểu chữ và lề của khối đó.
  double _titleBlockHeight(BuildContext context, Artifact artifact) {
    final scaler = MediaQuery.textScalerOf(context);
    // Gộp kiểu chữ mặc định mà Text trong Scaffold nhận (bodyMedium của theme:
    // phông, chiều cao dòng) — `context` ở đây nằm trên Scaffold nên không đọc
    // DefaultTextStyle được. Đo thiếu thì khối tên trồi lên dưới hàng nút.
    final base = Theme.of(context).textTheme.bodyMedium ??
        DefaultTextStyle.of(context).style;
    TextPainter measure(String text, TextStyle style, {double? maxWidth}) =>
        TextPainter(
          text: TextSpan(text: text, style: base.merge(style)),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: maxWidth == null ? 1 : 2,
        )..layout(maxWidth: maxWidth ?? double.infinity);

    final rating = measure(
      '${artifact.rating} (${artifact.reviewCount})',
      _ratingStyle,
    );
    final nameWidth = MediaQuery.sizeOf(context).width - 40 - 23 - rating.width;
    final name = measure(artifact.name, _nameStyle, maxWidth: nameWidth);
    final meta = measure('${artifact.era}${artifact.zone}', _metaStyle);
    final row1 = [name.height, rating.height, 20.0].reduce(math.max);
    final row2 = math.max(meta.height, 16.0);
    for (final p in [rating, name, meta]) {
      p.dispose();
    }
    return (16 + row1 + 6 + row2 + 8).ceilToDouble();
  }

  /// Nền hero: ảnh đại diện admin tải lên → ảnh đóng gói (bản khổ lớn nếu có) →
  /// gradient + icon. Xem [artifactPicture].
  Widget _heroBackground(Artifact artifact) {
    final asset = artifact.detailImageAsset ?? artifact.imageAsset;
    final hasImage = (artifact.imageUrl?.isNotEmpty ?? false) ||
        (asset != null && asset.isNotEmpty);
    if (hasImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          artifactPicture(
            artifact,
            asset: asset,
            alignment: artifact.detailImageAlignment,
            placeholder: () => _heroPlaceholder(artifact),
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
    return _heroPlaceholder(artifact);
  }

  Widget _heroPlaceholder(Artifact artifact) {
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _nameStyle,
                ),
              ),
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 3),
              Text(
                '${artifact.rating} (${artifact.reviewCount})',
                style: _ratingStyle,
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
                  style: _metaStyle,
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
                  style: _metaStyle,
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
    return CustomScrollView(
      slivers: [
        ...nestedOverlapInjector(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList.list(
            children: [
              // Nhắc người dùng: nội dung vẫn xem được ngoài vùng beacon.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.offline_pin_outlined,
                      color: AppColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.artifactSavedOffline,
                        style: const TextStyle(
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
              Text(
                context.l10n.artifactOverview,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (artifact.unavailableLanguage case final code?)
                _LanguageUnavailable(code: code)
              else ...[
                // description là HTML do trình soạn thảo của admin sinh ra, không phải
                // chữ thuần — phải parse mới thấy in đậm/danh sách như bên admin.
                RichTextContent(html: artifact.description),
                const SizedBox(height: 24),
                // Thuyết minh có màn hình riêng (kiểu now-playing) chứ không còn là tab.
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(AudioPlayerScreen.route(artifact)),
                  icon: const Icon(Icons.headphones_rounded, size: 20),
                  label: Text(context.l10n.artifactListen),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Hiện vật chưa có bản ngôn ngữ khách đang chọn: nói rõ thay vì để trống phần giới
/// thiệu và nút nghe không có gì để phát. Backend không lấy thứ tiếng khác thay vào.
class _LanguageUnavailable extends StatelessWidget {
  const _LanguageUnavailable({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final name = LanguageController.nativeName(code);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.artifactNoLanguage(name),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.artifactNoLanguageText,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
            icon: const Icon(Icons.language, size: 18),
            label: Text(context.l10n.changeLanguage),
          ),
        ],
      ),
    );
  }
}

class _GalleryTab extends StatefulWidget {
  const _GalleryTab({required this.artifact});

  final Artifact artifact;

  @override
  State<_GalleryTab> createState() => _GalleryTabState();
}

/// Ảnh thật từ `GET /artifacts/:id/media`. Chưa có ảnh nào (hoặc không gọi
/// được backend) thì giữ khung minh hoạ như cũ thay vì để tab trống trơn.
class _GalleryTabState extends State<_GalleryTab> {
  late final Future<List<GalleryImage>> _images = ArtifactRepository.instance
      .fetchImages(widget.artifact.id)
      .catchError((Object _) => const <GalleryImage>[]);

  Artifact get artifact => widget.artifact;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GalleryImage>>(
      future: _images,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final images = snapshot.data ?? const [];
        return images.isEmpty ? _placeholder(context) : _gallery(images);
      },
    );
  }

  Widget _gallery(List<GalleryImage> images) {
    return CustomScrollView(
      slivers: [
        ...nestedOverlapInjector(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final image = images[i];
              return GestureDetector(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(12),
                    child: InteractiveViewer(child: Image.network(image.url)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        image.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surfaceTint,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (image.caption case final caption?
                          when caption.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                            child: Text(
                              caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }, childCount: images.length),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ...nestedOverlapInjector(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      artifact.gradient.first.withValues(
                        alpha: 1 - (i % 3) * 0.18,
                      ),
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
                        context.l10n.artifactPhotoPlaceholder(i + 1, 6),
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
            }, childCount: 6),
          ),
        ),
      ],
    );
  }
}

class _VideoTab extends StatelessWidget {
  const _VideoTab({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ...nestedOverlapInjector(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList.list(
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
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 38,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            artifact.videoDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  i == 0
                      ? context.l10n.videoNarration(artifact.name)
                      : context.l10n.videoDocumentary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.videoSubtitles,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
