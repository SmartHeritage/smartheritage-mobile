import 'package:flutter/material.dart';

import '../data/artifact_repository.dart';
import '../state/visit_history_state.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/scan_choice_sheet.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'home/home_screen_v2.dart';
import 'map/map_screen.dart';
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

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
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
    void openTab(int i) => setState(() => _index = i);

    final screens = <Widget>[
      _useHomeV2 ? HomeScreenV2(onOpenTab: openTab) : const HomeScreen(),
      const MapScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      // Sidebar đặt ở đây (không ở HomeScreen) để phủ cả bottom nav + mini-player.
      // V2 bỏ hẳn sidebar: drawer null thì mất luôn cả cử chỉ vuốt mép màn
      // hình, không chỉ mất nút menu.
      drawer: _useHomeV2 ? null : const AppSidebar(),
      // Thanh dưới là kính mờ nổi: nội dung phải chạy xuống sau nó mới thấy
      // hiệu ứng. Các tab tự cộng `MediaQuery.paddingOf(context).bottom` (chiều
      // cao thanh + mini-player) vào lề dưới để phần cuối không bị che.
      extendBody: true,
      body: IndexedStack(index: _index, children: screens),
      // Thanh luôn hiện, không tự ẩn khi cuộn (đã bỏ theo yêu cầu 2026-10-20).
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          GlassNavBar(
            currentIndex: _index,
            onTap: openTab,
            // Nút quét to giữa Bản đồ và Yêu thích: chọn quét QR hoặc beacon.
            centerButton: GlassNavCenterButton(
              icon: Icons.qr_code_scanner,
              label: 'Quét mã QR hoặc beacon',
              onTap: () => showScanChoiceSheet(context),
            ),
            items: [
              // V2 có tiêu đề "Trang chủ" nên tab đầu gọi đúng tên đó.
              _useHomeV2
                  ? const GlassNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Trang chủ',
                    )
                  : const GlassNavItem(
                      icon: Icons.explore_outlined,
                      selectedIcon: Icons.explore,
                      label: 'Khám phá',
                    ),
              const GlassNavItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: 'Bản đồ',
              ),
              const GlassNavItem(
                icon: Icons.favorite_border,
                selectedIcon: Icons.favorite,
                label: 'Yêu thích',
              ),
              const GlassNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Cá nhân',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
