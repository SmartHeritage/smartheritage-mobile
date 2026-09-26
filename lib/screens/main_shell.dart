import 'package:flutter/material.dart';

import '../data/artifact_repository.dart';
import '../state/visit_history_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/mini_player_bar.dart';
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

  static const _screens = <Widget>[
    HomeScreen(),
    MapScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sidebar đặt ở đây (không ở HomeScreen) để phủ cả bottom nav + mini-player.
      // V2 bỏ hẳn sidebar: drawer null thì mất luôn cả cử chỉ vuốt mép màn
      // hình, không chỉ mất nút menu.
      drawer: _useHomeV2 ? null : const AppSidebar(),
      // Chế độ V2 không có tab: trang chủ là toàn bộ app, các màn hình khác
      // mở bằng lưới tính năng và push thành route.
      body: _useHomeV2
          ? const HomeScreenV2()
          : IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          if (!_useHomeV2)
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: Colors.white,
              indicatorColor: AppColors.surfaceTint,
              surfaceTintColor: Colors.transparent,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore, color: AppColors.primary),
                  label: 'Khám phá',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map, color: AppColors.primary),
                  label: 'Bản đồ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite, color: AppColors.primary),
                  label: 'Yêu thích',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.primary),
                  label: 'Cá nhân',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
