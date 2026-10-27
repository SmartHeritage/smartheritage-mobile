import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../data/news_repository.dart';
import '../../l10n/l10n.dart';
import '../../state/audio_player_state.dart';
import '../../state/auth_state.dart';
import '../../state/beacon_scan_state.dart';
import '../../state/news_inbox_state.dart';
import '../../state/language_state.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../../widgets/beacon_choice_sheet.dart';
import '../artifact/artifact_detail_screen.dart';
import '../favorites/favorites_screen.dart';
import '../feedback/feedback_screen.dart';
import '../help/help_screen.dart';
import '../history/history_screen.dart';
import '../map/map_screen.dart';
import '../about/about_screen.dart';
import '../news/news_detail_screen.dart';
import '../profile/language_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/beacon_scan_screen.dart';
import 'home_screen.dart' show BeaconDetectedSheet;

/// Bản dựng thử trang chủ theo ngôn ngữ thị giác của app HCMC Metro: hero
/// card bo góc lớn, lưới tính năng icon tròn, carousel ngang, nền phớt màu.
///
/// Ban đầu bản này bỏ bottom nav giống Metro (lưới 8 ô là điều hướng duy
/// nhất); từ 2026-10-19 V2 cũng có thanh điều hướng kính mờ như V1 theo yêu
/// cầu. Ô trong lưới đều push thành route: từ 2026-10-21 các tab là Danh sách
/// nghe, Thông báo, Tài khoản (chỉ xem), còn ô Cài đặt mở trang cá nhân cũ.
///
/// Khác Metro một điểm: lưới chỉ có MỘT trang. Metro chia 2 trang và nhét
/// Bản đồ, Tour ảo, Sự kiện xuống trang 2 — gần như không ai vuốt tới. Tám ô
/// vừa đủ một màn nên bỏ luôn PageView.
///
/// Bản này cũng không có sidebar lẫn màn hình thông báo: header chỉ còn nút
/// chọn ngôn ngữ, mọi lối đi khác đều nằm trong lưới.
///
/// Bật bằng: flutter run --dart-define=HOME_V2=true
class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final _scan = BeaconScanController.instance;
  bool _sheetShown = false;

  @override
  void initState() {
    super.initState();
    _scan.addListener(_onScanChanged);
  }

  @override
  void dispose() {
    _scan.removeListener(_onScanChanged);
    super.dispose();
  }

  /// Beacon chỉ một hiện vật: như bản gốc, tự phát thuyết minh rồi mở sheet.
  /// Beacon nhiều hiện vật: hiện danh sách, đợi khách chọn rồi mới làm như
  /// trên với hiện vật được chọn.
  void _onScanChanged() {
    final artifact = _scan.detected;
    if (artifact == null || _sheetShown || !mounted) return;
    final choices = _scan.detectedChoices;
    _scan.consumeDetection();
    if (choices.length > 1) {
      _showChoiceSheet(choices);
      return;
    }
    _announce(artifact);
  }

  void _announce(Artifact artifact) {
    // Khách chưa đăng nhập thì không tự phát — sheet mời đăng nhập để nghe.
    if (artifact.hasAudio && AuthController.instance.isLoggedIn) {
      AudioPlayerController.instance.play(artifact);
    }
    _showBeaconSheet(artifact);
  }

  Future<void> _showChoiceSheet(List<Artifact> choices) async {
    _sheetShown = true;
    final picked = await showModalBottomSheet<Artifact>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BeaconChoiceSheet(artifacts: choices),
    );
    _sheetShown = false;
    if (picked == null || !mounted) return;
    _scan.reportChoice(picked);
    _announce(picked);
  }

  void _showBeaconSheet(Artifact artifact) {
    _sheetShown = true;
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArtifactRepository.instance,
        NewsRepository.instance,
      ]),
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Nền là ảnh minh hoạ chung của các tab V2, vẽ ở MainShell (2026-10-21) —
    // trước đây là gradient phớt nâu đỏ → trắng vẽ ngay tại đây, giờ để trong
    // suốt cho ảnh lộ ra.
    // Không chừa lề dưới ở SafeArea: danh sách chạy xuống sau thanh điều
    // hướng, lề cuối đã cộng chiều cao thanh.
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => Future.wait([
          ArtifactRepository.instance.refresh(),
          NewsRepository.instance.refresh(),
        ]),
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 28 + MediaQuery.paddingOf(context).bottom,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _pad(_buildTopBar(context)),
            if (ArtifactRepository.instance.isOffline) ...[
              const SizedBox(height: 12),
              _pad(_buildOfflineBanner()),
            ],
            const SizedBox(height: 16),
            _pad(const _HeroCard()),
            const SizedBox(height: 22),
            _pad(_buildFeatureGrid(context)),
            const SizedBox(height: 26),
            _buildRecentVisits(),
            _buildFeaturedCarousel(),
            _buildNewsCarousel(),
          ],
        ),
      ),
    );
  }

  /// ListView không đặt padding ngang chung, vì carousel phải tràn sát mép.
  Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );

  /// Hàng trên cùng: tiêu đề bên trái, nút chọn ngôn ngữ bên phải. Đã đăng nhập
  /// thì tiêu đề là lời chào kèm họ tên tài khoản thay cho "Trang chủ".
  ///
  /// Không có nút menu vì bản này bỏ sidebar, và không có chuông vì bỏ luôn
  /// màn hình thông báo. Mọi lối đi đều nằm trong lưới tính năng.
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        // Tên dài thì cắt bằng "…" chứ không đẩy chip ngôn ngữ ra khỏi màn.
        Expanded(
          child: ListenableBuilder(
            listenable: AuthController.instance,
            builder: (context, _) {
              final auth = AuthController.instance;
              final user = auth.isLoggedIn ? auth.user : null;
              return Text(
                // Chưa nhập họ tên thì displayName lấy phần trước @ của email.
                user == null
                    ? context.l10n.navHome
                    : context.l10n.homeGreeting(user.displayName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // Chip có chữ co giãn (Flexible) bên trong nên cần bề ngang có giới hạn;
        // không bọc Flexible ở đây vì sẽ chia đôi chỗ với tiêu đề.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: _LanguageChip(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
          ),
        ),
      ],
    );
  }

  /// Lưới 8 tính năng, điều hướng chính của màn hình.
  ///
  /// Xếp 2 hàng 4 ô trên một trang duy nhất. Tài khoản trùng với tab ở thanh
  /// dưới nên chuyển tab, không mở thêm một bản.
  Widget _buildFeatureGrid(BuildContext context) {
    void push(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return ListenableBuilder(
      listenable: _scan,
      builder: (context, _) {
        final items = <_Feature>[
          _Feature(
            icon: Icons.map_outlined,
            label: context.l10n.navMap,
            onTap: () => push(const MapScreen()),
          ),
          _Feature(
            icon: _scan.isScanning
                ? Icons.bluetooth_searching
                : Icons.bluetooth,
            label: _scan.isScanning
                ? context.l10n.homeScanning
                : context.l10n.scanBeaconTitle,
            active: _scan.isScanning,
            // Sang trang quét riêng (nút Bluetooth lớn), giống lựa chọn
            // "Quét beacon" ở nút quét giữa thanh điều hướng.
            // Quét beacon phải đăng nhập — hỏi trước khi sang trang quét.
            onTap: () async {
              if (await AuthController.ensureLoggedIn(context)) {
                push(const BeaconScanScreen());
              }
            },
          ),
          _Feature(
            icon: Icons.favorite_border,
            label: context.l10n.navFavorites,
            // Tab thứ ba giờ là Thông báo (2026-10-21) → Yêu thích mở thành
            // trang riêng.
            onTap: () => push(const FavoritesScreen()),
          ),
          // Thay ô "Đang nghe" (2026-10-21): bài đang phát đã có mini-player
          // ngay trên thanh điều hướng.
          _Feature(
            icon: Icons.info_outline,
            label: context.l10n.homeAbout,
            onTap: () => push(const AboutScreen()),
          ),
          _Feature(
            icon: Icons.history,
            label: context.l10n.homeHistory,
            onTap: () => push(const HistoryScreen()),
          ),
          _Feature(
            icon: Icons.rate_review_outlined,
            label: context.l10n.homeFeedback,
            onTap: () => push(const FeedbackScreen()),
          ),
          _Feature(
            icon: Icons.help_outline,
            label: context.l10n.homeHelp,
            onTap: () => push(const HelpScreen()),
          ),
          // Thay ô Tài khoản (2026-10-21): tab Tài khoản giờ chỉ xem thông
          // tin, các thiết lập (sửa thông tin, ngôn ngữ, quét, đăng xuất…)
          // nằm ở trang cá nhân cũ mở từ đây. Khách vẫn vào được — trang tự
          // hiện thẻ mời đăng nhập.
          _Feature(
            icon: Icons.settings_outlined,
            label: context.l10n.settingsTitle,
            onTap: () => push(
              ProfileScreen(
                title: context.l10n.settingsTitle,
                showEditProfile: false,
                linkAbout: true,
                showAccountCard: false,
              ),
            ),
          ),
        ];

        // Hai hàng 4 ô dựng bằng Row lồng Column, không dùng GridView: lưới
        // nằm trong ListView nên GridView sẽ phải shrinkWrap + tắt cuộn, rườm
        // rà hơn mà kết quả y hệt.
        return Column(
          children: [
            _gridRow(items.sublist(0, 4)),
            const SizedBox(height: 18),
            _gridRow(items.sublist(4, 8)),
          ],
        );
      },
    );
  }

  Widget _gridRow(List<_Feature> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Expanded(
            child: _QuickAction(
              icon: item.icon,
              label: item.label,
              active: item.active,
              onTap: item.onTap,
            ),
          ),
      ],
    );
  }

  /// Carousel ngang — đúng chỗ Metro đặt banner khuyến mãi. Ở đây dùng dữ
  /// liệu thật (hiện vật nổi bật) thay vì banner quảng cáo.
  Widget _buildFeaturedCarousel() {
    final featured = ArtifactRepository.instance.artifacts.take(6).toList();
    if (featured.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pad(SectionHeader(title: context.l10n.homeFeatured)),
        const SizedBox(height: 12),
        SizedBox(
          height: 252,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _FeaturedSlide(artifact: featured[i]),
          ),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  /// Carousel tin tức — cùng dạng với "Nổi bật" nhưng thẻ thấp hơn vì không
  /// có hàng sao/thời kỳ, chỉ ảnh bìa, tiêu đề và ngày. Bài viết đã xuất bản
  /// ở admin; chưa có bài nào thì ẩn cả mục.
  Widget _buildNewsCarousel() {
    final news = NewsRepository.instance.items;
    if (news.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pad(SectionHeader(title: context.l10n.homeNews)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: news.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _NewsSlide(item: news[i]),
          ),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildRecentVisits() {
    return ListenableBuilder(
      listenable: VisitHistoryController.instance,
      builder: (context, _) {
        final records = VisitHistoryController.instance.records;
        if (records.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pad(
              SectionHeader(
                title: context.l10n.homeRecentVisits,
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final record in records.take(3)) ...[
              _pad(
                ArtifactListTile(
                  artifact: record.artifact,
                  subtitle: '${record.dateLabel} · ${record.timeLabel}',
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.homeOffline,
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
            child: Text(
              context.l10n.retry,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero card đầu trang — vị trí banner tàu điện của Metro.
///
/// Dùng gradient + hoạ tiết vẽ bằng code, không mượn hình minh hoạ của họ.
/// Khi có ảnh bảo tàng thật thì thay nền này bằng ảnh, phần chữ giữ nguyên.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Màu nền trùng tông ảnh, để khung không loé trắng trong lúc ảnh
        // đang giải mã ở lần dựng đầu.
        color: AppColors.primaryDark,
        image: const DecorationImage(
          image: AssetImage('assets/images/hero_museum.jpg'),
          // Ảnh 2.38:1 mà thẻ cao 210 chỉ khoảng 1.7:1 (máy 390pt), nên
          // cover cắt mất gần 30% bề ngang. Neo phải: chủ thể (đền + trống
          // đồng) nằm sát mép phải, phần bị cắt là mặt hồ trống bên trái —
          // vốn chỉ là nền cho tiêu đề.
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // Lớp phủ tối dồn về trái, chỗ đặt tiêu đề. Vùng đó trong ảnh sáng
          // trung bình 45/255 nên chữ trắng đã đọc được, nhưng có mảng lá và
          // mặt nước vọt lên 152 — phủ thêm để không chỗ nào bị chìm chữ.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.55),
                    AppColors.primaryDark.withValues(alpha: 0.0),
                  ],
                  stops: const [0, 0.75],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.homeOfficialApp,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Heritage',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.homeHeroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
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

/// Một ô trong lưới tính năng. Gom thành kiểu riêng để dựng lưới bằng vòng
/// lặp thay vì chép tay tám khối widget gần giống nhau.
class _Feature {
  const _Feature({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Chỉ dùng cho ô quét beacon — ô sáng lên khi đang quét.
  final bool active;
}

/// Icon tròn nền trắng + nhãn dưới — hình dáng lấy từ lưới icon của Metro.
/// Một ô của lưới tính năng. Bấm vào: vòng tròn icon nhún nhỏ lại khi đang
/// nhấn rồi bật lại khi thả, kèm một nhịp rung nhẹ (2026-10-21). Không dùng
/// InkWell: vệt loang của nó vẽ dưới vòng tròn trắng nên chỉ lộ một quầng xám
/// quanh mép ô, trên ảnh nền gần như không thấy.
class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Semantics(
      button: true,
      child: GestureDetector(
        // Bấm cả vùng ô (kể cả chữ, khoảng trống), không chỉ vòng tròn.
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedScale(
                scale: _pressed ? 0.9 : 1,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: active ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ trong carousel ngang — khổ hẹp hơn card dọc của bản gốc để lộ một
/// phần thẻ kế bên, gợi ý vuốt được.
class _FeaturedSlide extends StatelessWidget {
  const _FeaturedSlide({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openArtifactDetail(context, artifact),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // width 0 là hairline: Flutter vẽ đúng 1 pixel vật lý, mảnh nhất
          // thiết bị làm được. Để 1.0 thì trên màn 3x thành 3 pixel, dày gấp
          // ba. Alpha 0.35 để đường viền có sắc nâu đỏ mà không thành khung
          // đậm bao quanh ảnh.
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  ArtifactImage(artifact: artifact, height: 160),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: FavoriteButton(artifact: artifact),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
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
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artifact.zone,
                            style: const TextStyle(
                              fontSize: 11.5,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artifact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          artifact.era,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
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

/// Thẻ tin tức trong carousel. Cùng bề ngang và cùng kiểu viền với
/// [_FeaturedSlide] để hai dải dưới trang chủ đọc ra là một hệ.
class _NewsSlide extends StatelessWidget {
  const _NewsSlide({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Đọc từ trang chủ cũng tính là đã đọc ở tab Thông báo.
        NewsInboxController.instance.markRead(item);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)));
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: NewsCover(item: item, height: 92),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Đẩy ngày xuống đáy thẻ để các thẻ thẳng hàng nhau dù tiêu
                    // đề dài ngắn khác nhau.
                    const Spacer(),
                    if (item.dateLabel.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.dateLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              // Ngôn ngữ đang chọn (trước đây ghi cứng "Tiếng Việt").
              child: ListenableBuilder(
                listenable: LanguageController.instance,
                builder: (context, _) {
                  final code = LanguageController.instance.code;
                  return Text(
                    LanguageController.nativeName(code),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
