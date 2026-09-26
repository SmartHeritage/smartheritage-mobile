import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../state/audio_player_state.dart';
import '../../state/auth_state.dart';
import '../../state/beacon_scan_state.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';
import '../artifact/artifact_detail_screen.dart';
import '../favorites/favorites_screen.dart';
import '../feedback/feedback_screen.dart';
import '../help/help_screen.dart';
import '../history/history_screen.dart';
import '../map/map_screen.dart';
import '../news/news_detail_screen.dart';
import '../profile/language_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart' show BeaconDetectedSheet;

/// Bản dựng thử trang chủ theo ngôn ngữ thị giác của app HCMC Metro: hero
/// card bo góc lớn, lưới tính năng icon tròn, carousel ngang, nền phớt màu.
///
/// Ở chế độ này bottom nav bị bỏ — lưới 8 ô chính là điều hướng duy nhất,
/// đúng như Metro. Bản đồ / Yêu thích / Tài khoản không còn là tab mà được
/// push thành route, nên ba màn hình đó tự mọc nút back từ AppBar sẵn có.
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

  /// Giữ nguyên hành vi của bản gốc: beacon bắt được hiện vật thì tự phát
  /// thuyết minh rồi mở sheet.
  void _onScanChanged() {
    final artifact = _scan.detected;
    if (artifact == null || _sheetShown || !mounted) return;
    _scan.consumeDetection();
    if (artifact.hasAudio) {
      AudioPlayerController.instance.play(artifact);
    }
    _showBeaconSheet(artifact);
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
      listenable: ArtifactRepository.instance,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Nền chuyển dọc: phớt nâu đỏ ở đỉnh, trắng dần xuống đáy — thủ pháp của
    // app Metro, giúp các card trắng (hero, icon tròn, thẻ hiện vật) nổi lên
    // mà không cần viền.
    //
    // stops [0, 1] để chuyển trải đều cả trang. Để stop kết thúc sớm (0.45
    // như bản đầu) thì nửa dưới là một mảng trắng phẳng, nhìn thành hai khối
    // màu rời nhau chứ không phải một dải liền.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceTint, AppColors.background],
          stops: [0, 1],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: ArtifactRepository.instance.refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
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
      ),
    );
  }

  /// ListView không đặt padding ngang chung, vì carousel phải tràn sát mép.
  Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );

  /// Hàng trên cùng: tiêu đề "Trang chủ" bên trái, nút chọn ngôn ngữ bên phải.
  ///
  /// Không có nút menu vì bản này bỏ sidebar, và không có chuông vì bỏ luôn
  /// màn hình thông báo. Mọi lối đi đều nằm trong lưới tính năng.
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Trang chủ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        // Chip nằm trong Expanded căn phải, không dùng Spacer: nếu để Spacer
        // và chip cùng là flex child thì hai đứa chia đôi khoảng trống và chip
        // bị cắt chữ dù còn thừa chỗ.
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: _LanguageChip(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lưới 8 tính năng — thay hoàn toàn bottom nav, đây là điều hướng chính
  /// của màn hình.
  ///
  /// Xếp 2 hàng 4 ô trên một trang duy nhất. Ba ô đầu (Bản đồ, Yêu thích,
  /// Tài khoản) chính là ba tab cũ, giờ push thành route.
  Widget _buildFeatureGrid(BuildContext context) {
    void push(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return ListenableBuilder(
      listenable: _scan,
      builder: (context, _) {
        final items = <_Feature>[
          _Feature(
            icon: Icons.map_outlined,
            label: 'Bản đồ',
            onTap: () => push(const MapScreen()),
          ),
          _Feature(
            icon: _scan.isScanning
                ? Icons.bluetooth_searching
                : Icons.bluetooth,
            label: _scan.isScanning ? 'Đang quét' : 'Quét beacon',
            active: _scan.isScanning,
            onTap: _scan.toggle,
          ),
          _Feature(
            icon: Icons.favorite_border,
            label: 'Yêu thích',
            onTap: () => push(const FavoritesScreen()),
          ),
          _Feature(
            icon: Icons.headphones_outlined,
            label: 'Đang nghe',
            onTap: () => _openCurrentAudio(context),
          ),
          _Feature(
            icon: Icons.history,
            label: 'Lịch sử',
            onTap: () => push(const HistoryScreen()),
          ),
          _Feature(
            icon: Icons.rate_review_outlined,
            label: 'Góp ý',
            onTap: () => push(const FeedbackScreen()),
          ),
          _Feature(
            icon: Icons.help_outline,
            label: 'Trợ giúp',
            onTap: () => push(const HelpScreen()),
          ),
          _Feature(
            icon: Icons.person_outline,
            label: 'Tài khoản',
            onTap: () => _openAccount(context),
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

  /// Ô "Tài khoản": khách chưa đăng nhập thì đưa thẳng vào trang đăng nhập,
  /// đăng nhập rồi mới vào trang cá nhân.
  ///
  /// Trang cá nhân vốn tự xử lý được trạng thái khách (hiện card mời đăng
  /// nhập), nhưng như vậy khách phải bấm thêm một nhịp nữa mới tới được form.
  Future<void> _openAccount(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!AuthController.instance.isLoggedIn) {
      // Huỷ giữa chừng (bấm back ở trang đăng nhập) thì dừng, không mở tiếp
      // trang cá nhân rỗng.
      final loggedIn = await AuthController.ensureLoggedIn(context);
      if (!loggedIn || !mounted) return;
    }
    navigator.push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  /// Mở trình phát của hiện vật đang nghe. Chưa phát gì thì nói thẳng thay vì
  /// mở một màn hình trống.
  void _openCurrentAudio(BuildContext context) {
    final artifact = AudioPlayerController.instance.artifact;
    if (artifact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có bản thuyết minh nào đang phát.'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtifactDetailScreen(artifact: artifact),
      ),
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
        _pad(const SectionHeader(title: 'Nổi bật')),
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
  /// có hàng sao/thời kỳ, chỉ ảnh bìa, tiêu đề và ngày.
  Widget _buildNewsCarousel() {
    const news = MockData.news;
    if (news.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pad(const SectionHeader(title: 'Tin tức')),
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
                title: 'Tham quan gần đây',
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
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Màu nền trùng tông ảnh, để khung không loé trắng trong lúc ảnh
        // đang giải mã ở lần dựng đầu.
        color: AppColors.primaryDark,
        image: const DecorationImage(
          image: AssetImage('assets/images/hero_museum.jpg'),
          // Ảnh 2.38:1 đúng bằng tỉ lệ thẻ trên máy rộng nhất. Máy hẹp hơn
          // thì cover cắt bớt hai bên — chủ thể nằm lệch phải nên phần mất
          // là khoảng nền trống bên trái.
          fit: BoxFit.cover,
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
              child: const Text(
                'Ứng dụng chính thức',
                style: TextStyle(
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
                  'Đến gần hiện vật, thuyết minh tự phát',
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
class _QuickAction extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: active ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArtifactDetailScreen(artifact: artifact),
        ),
      ),
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item))),
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
              child: Image.asset(
                item.imageAsset,
                height: 92,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: AppColors.primary),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Tiếng Việt',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
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
