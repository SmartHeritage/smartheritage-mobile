import 'package:flutter/material.dart';

import '../data/artifact_repository.dart';
import '../data/news_repository.dart';
import '../l10n/l10n.dart';
import '../state/audio_player_state.dart';
import '../state/auth_state.dart';
import '../state/beacon_scan_state.dart';
import '../state/news_inbox_state.dart';
import '../state/visit_history_state.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/scan_choice_sheet.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'home/home_screen_v2.dart';
import 'notification/news_inbox_screen.dart';
import 'playlist/playlist_screen.dart';
import 'profile/account_info_screen.dart';
import 'profile/profile_screen.dart';

/// Khung chính của app với thanh điều hướng dưới cùng.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.beaconArtifactId});

  /// Khi mở app từ thông báo FCM (beacon phát hiện di sản), truyền id hiện vật
  /// để nhảy thẳng vào màn phát hiện — không cần đăng nhập.
  final String? beaconArtifactId;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  /// Mỗi tab một controller, truyền xuống bằng [PrimaryScrollController]: trên điện
  /// thoại, danh sách cuộn dọc không tự đặt controller sẽ dùng nó, nên không phải
  /// sửa từng màn. Các tab sống trong IndexedStack nên vẫn giữ chỗ cuộn cũ — đổi
  /// tab thì kéo tab mới về đầu (xem [_scrollToTop]).
  final _scrollControllers = List.generate(4, (_) => ScrollController());

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthController.instance.removeListener(_onAuthChanged);
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Chưa có thông báo đẩy nên bài mới chỉ tới khi app tự hỏi lại: mỗi lần
  /// khách mở lại app thì tải lại tin để chấm đỏ tab Thông báo (V2) kịp thời.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Giải mã ảnh nền trước khi khung dựng xong, khỏi chớp trắng lúc mở app.
    if (_useHomeV2) precacheImage(_V2Background.image, context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _useHomeV2) {
      NewsRepository.instance.refresh();
    }
  }

  /// Nghe thuyết minh và quét beacon phải đăng nhập (2026-10-21): đăng xuất
  /// (hay phiên bị thu hồi) thì tắt bài đang phát và dừng quét, khỏi thành
  /// khách mà vẫn dùng tiếp.
  void _onAuthChanged() {
    if (AuthController.instance.isLoggedIn) return;
    final player = AudioPlayerController.instance;
    if (player.artifact != null) player.close();
    final scan = BeaconScanController.instance;
    if (scan.isScanning) scan.stopScan();
  }

  /// Đưa tab [i] về đầu trang. Tab sắp hiện thì nhảy thẳng (chưa thấy nên không
  /// cần hoạt ảnh); bấm lại tab đang mở thì cuộn mượt lên đầu như app iOS.
  void _scrollToTop(int i, {required bool animate}) {
    for (final position in _scrollControllers[i].positions) {
      if (animate) {
        position.animateTo(
          position.minScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        position.jumpTo(position.minScrollExtent);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    AuthController.instance.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    final id = widget.beaconArtifactId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openBeacon(id));
    }
  }

  void _openBeacon(String artifactId) {
    if (!mounted) return;
    final artifact = ArtifactRepository.instance.byId(artifactId);
    // Mở từ thông báo FCM beacon → cũng ghi vào lịch sử tham quan (local).
    VisitHistoryController.instance.recordBeaconVisit(artifact);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BeaconDetectedSheet(artifact: artifact),
    );
  }

  /// Bản dựng thử trang chủ theo phong cách app Metro. Tạm thời để sau một cờ
  /// build để so trực tiếp hai bản; chốt xong thì bỏ cờ và xoá bản thua.
  /// `flutter run --dart-define=HOME_V2=true`
  static const _useHomeV2 = bool.fromEnvironment('HOME_V2');

  @override
  Widget build(BuildContext context) {
    void openTab(int i) {
      if (i == _index) return _scrollToTop(i, animate: true);
      _scrollToTop(i, animate: false);
      // Vào tab Thông báo thì hỏi lại xem có bài mới không.
      if (_useHomeV2 && i == 2 && AuthController.instance.isLoggedIn) {
        NewsInboxController.instance.refresh();
      }
      setState(() => _index = i);
    }

    final screens = <Widget>[
      for (final (i, screen) in <Widget>[
        _useHomeV2 ? const HomeScreenV2() : const HomeScreen(),
        const PlaylistScreen(),
        // V2 thay tab Yêu thích bằng Thông báo (2026-10-21); Yêu thích vẫn mở
        // từ ô trong lưới trang chủ. V1 giữ nguyên.
        _useHomeV2 ? const NewsInboxScreen() : const FavoritesScreen(),
        // V2: tab Tài khoản chỉ xem thông tin (2026-10-21); trang cá nhân cũ
        // mở từ ô Cài đặt ở trang chủ. V1 giữ nguyên.
        _useHomeV2 ? const AccountInfoScreen() : const ProfileScreen(),
      ].indexed)
        PrimaryScrollController(
          controller: _scrollControllers[i],
          child: screen,
        ),
    ];
    return Scaffold(
      // Sidebar đặt ở đây (không ở HomeScreen) để phủ cả bottom nav + mini-player.
      // V2 bỏ hẳn sidebar: drawer null thì mất luôn cả cử chỉ vuốt mép màn
      // hình, không chỉ mất nút menu.
      drawer: _useHomeV2 ? null : const AppSidebar(),
      // Nút quét trồi lên khỏi thanh dưới, dải trồi lên trong suốt — thân trang
      // phải chạy xuống sau thanh mới thấy nội dung quanh nút. Các tab tự cộng
      // `MediaQuery.paddingOf(context).bottom` (chiều cao thanh + mini-player)
      // vào lề dưới để phần cuối không bị che.
      extendBody: true,
      body: _useHomeV2
          ? _V2Background(
              child: IndexedStack(index: _index, children: screens),
            )
          : IndexedStack(index: _index, children: screens),
      // Thanh luôn hiện, không tự ẩn khi cuộn (đã bỏ theo yêu cầu 2026-10-20).
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([
          AudioPlayerController.instance,
          // Chấm số bài chưa đọc trên tab Thông báo.
          if (_useHomeV2) NewsInboxController.instance,
        ]),
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerBar(),
            AppNavBar(
              currentIndex: _index,
              onTap: openTab,
              // Nút quét giữa Danh sách nghe và Yêu thích: to và trồi lên khỏi thanh; khi
              // mini-player hiện ngay trên thanh thì thu nhỏ vào trong, khỏi đè nó.
              raiseCenter: !MiniPlayerBar.isShown(
                AudioPlayerController.instance,
              ),
              centerButton: AppNavCenterButton(
                icon: Icons.qr_code_scanner,
                label: context.l10n.navScan,
                onTap: () => showScanChoiceSheet(context),
              ),
              items: [
                // V2 có tiêu đề "Trang chủ" nên tab đầu gọi đúng tên đó.
                _useHomeV2
                    ? AppNavItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: context.l10n.navHome,
                      )
                    : AppNavItem(
                        icon: Icons.explore_outlined,
                        selectedIcon: Icons.explore,
                        label: context.l10n.navExplore,
                      ),
                // Thay tab Bản đồ (2026-10-21); bản đồ mở từ ô Bản đồ ở
                // trang chủ V2.
                AppNavItem(
                  icon: Icons.queue_music_outlined,
                  selectedIcon: Icons.queue_music,
                  label: context.l10n.navPlaylist,
                ),
                _useHomeV2
                    ? AppNavItem(
                        icon: Icons.notifications_none_rounded,
                        selectedIcon: Icons.notifications_rounded,
                        label: context.l10n.navNotifications,
                        badgeCount: NewsInboxController.instance.unreadCount,
                      )
                    : AppNavItem(
                        icon: Icons.favorite_border,
                        selectedIcon: Icons.favorite,
                        label: context.l10n.navFavorites,
                      ),
                AppNavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  // V2: tab chỉ xem thông tin tài khoản, gọi đúng tên màn.
                  label: _useHomeV2
                      ? context.l10n.accountInfoTitle
                      : context.l10n.navProfile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ảnh nền minh hoạ (tông sepia: cành lá, mây, cổng cổ, sen) phía sau các tab
/// của V2 (2026-10-21, ảnh người dùng làm cỡ 1284×2778). Chỉ các tab: trang mở
/// chồng lên (chi tiết hiện vật, Cài đặt, Giới thiệu…) là route riêng, vẫn nền
/// trắng để nội dung dài dễ đọc.
///
/// Các tab vốn có Scaffold/AppBar nền trắng → ghi đè theme ngay tại đây cho
/// trong suốt, khỏi sửa từng màn. Tab mới thêm vào thì tự hưởng, miễn đừng đặt
/// `backgroundColor` cứng cho Scaffold/AppBar của nó.
class _V2Background extends StatelessWidget {
  const _V2Background({required this.child});

  final Widget child;

  static const image = AssetImage('assets/images/app_background.jpg');

  /// Độ đậm của ảnh trên nền trắng: 1 = ảnh gốc, càng nhỏ lớp trắng phủ càng dày.
  static const _imageOpacity = 0.3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        // Lớp phủ trắng tinh (theo yêu cầu, thay lớp kem trùng màu ảnh): ảnh
        // chỉ đậm [_imageOpacity] trên nền trắng nên cả nét vẽ lẫn màu sepia
        // nhạt đi, chữ đặt thẳng trên nền (tiêu đề, nhãn lưới trang chủ) dễ
        // đọc hơn (2026-10-21). Cũng là màu chờ khi ảnh chưa giải mã xong.
        color: Colors.white,
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
          opacity: _imageOpacity,
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            // Material 3 tô màu thanh tiêu đề khi nội dung cuộn dưới nó — trên
            // nền ảnh thành một dải màu lạc lõng.
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
        ),
        child: child,
      ),
    );
  }
}
