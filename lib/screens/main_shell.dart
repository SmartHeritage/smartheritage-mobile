import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../state/visit_history_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
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
    final artifact = MockData.artifacts.firstWhere(
      (a) => a.id == artifactId,
      orElse: () => MockData.artifacts.first,
    );
    // Mở từ thông báo FCM beacon → cũng ghi vào lịch sử tham quan (local).
    VisitHistoryController.instance.recordBeaconVisit(artifact);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BeaconDetectedSheet(artifact: artifact),
    );
  }

  static const _screens = <Widget>[
    HomeScreen(),
    MapScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
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
