import 'package:flutter/material.dart';

import '../screens/history/history_screen.dart';
import '../screens/profile/language_screen.dart';
import '../state/auth_state.dart';
import '../state/beacon_scan_state.dart';
import '../theme/app_theme.dart';

/// Sidebar của app, mở từ nút menu ở header trang chủ.
///
/// Gắn vào [Scaffold] của MainShell nên trượt ra phủ cả thanh điều hướng dưới
/// và mini-player.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListenableBuilder(
        listenable: AuthController.instance,
        builder: (context, _) {
          final auth = AuthController.instance;
          return Column(
            children: [
              _Header(auth: auth),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const _ScanToggle(),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _Item(
                      icon: Icons.history,
                      label: 'Lịch sử tham quan',
                      onTap: () => _open(context, const HistoryScreen()),
                    ),
                    _Item(
                      icon: Icons.language,
                      label: 'Ngôn ngữ',
                      onTap: () => _open(context, const LanguageScreen()),
                    ),
                  ],
                ),
              ),
              if (auth.isLoggedIn)
                SafeArea(
                  top: false,
                  child: _Item(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    color: AppColors.danger,
                    onTap: () {
                      Scaffold.of(context).closeDrawer();
                      _confirmLogout(context);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Đóng sidebar rồi mới push — giữ Navigator sạch, không để drawer mở phía sau.
  void _open(BuildContext context, Widget screen) {
    Scaffold.of(context).closeDrawer();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Đăng xuất về chế độ khách, vẫn ở trong app.
              AuthController.instance.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  auth.isLoggedIn ? Icons.person : Icons.person_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                auth.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              if (auth.isLoggedIn)
                Text(
                  auth.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                )
              else
                _LoginChip(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          Scaffold.of(context).closeDrawer();
          AuthController.ensureLoggedIn(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Đăng nhập / Đăng ký',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Công tắc quét iBeacon — dùng chung state với card trên trang chủ.
class _ScanToggle extends StatelessWidget {
  const _ScanToggle();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BeaconScanController.instance,
      builder: (context, _) {
        final scanning = BeaconScanController.instance.isScanning;
        return SwitchListTile(
          value: scanning,
          onChanged: (_) => BeaconScanController.instance.toggle(),
          activeThumbColor: AppColors.primary,
          secondary: Icon(
            scanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            color: scanning ? AppColors.primary : AppColors.textSecondary,
          ),
          title: const Text(
            'Quét iBeacon',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            scanning ? 'Đang tìm hiện vật ở gần bạn…' : 'Đang tắt',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
