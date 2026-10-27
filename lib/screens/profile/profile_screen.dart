import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_state.dart';
import '../../state/beacon_scan_state.dart';
import '../../state/language_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beacon_scan_toggle.dart';
import '../about/about_screen.dart';
import '../auth/register_screen.dart';
import '../feedback/feedback_screen.dart';
import '../help/help_screen.dart';
import '../history/history_screen.dart';
import 'edit_profile_screen.dart';
import 'language_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.title,
    this.showEditProfile = true,
    this.linkAbout = false,
    this.showAccountCard = true,
  });

  /// Tiêu đề thanh trên; mặc định "Tài khoản của tôi". V2 mở trang này từ ô
  /// Cài đặt ở trang chủ nên đặt "Cài đặt".
  final String? title;

  /// Mục "Chỉnh sửa thông tin cá nhân". Trang Cài đặt của V2 bỏ mục này theo
  /// yêu cầu (2026-10-21); V1 vẫn có.
  final bool showEditProfile;

  /// Mục "Về ứng dụng" mở trang Giới thiệu. Chỉ trang Cài đặt của V2 bật
  /// (2026-10-21); V1 giữ nguyên.
  final bool linkAbout;

  /// Thẻ thông tin tài khoản đầu trang (avatar, tên, email) khi đã đăng nhập.
  /// Trang Cài đặt của V2 bỏ thẻ này (2026-10-21) vì đã có tab Thông tin tài
  /// khoản; khách vẫn thấy thẻ mời đăng nhập. V1 giữ nguyên.
  final bool showAccountCard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? context.l10n.profileTitle)),
      body: ListenableBuilder(
        listenable: AuthController.instance,
        builder: (context, _) {
          final isLoggedIn = AuthController.instance.isLoggedIn;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 32 + MediaQuery.paddingOf(context).bottom),
            children: [
              if (showAccountCard || !isLoggedIn) ...[
                _buildProfileCard(context),
                const SizedBox(height: 24),
              ],
              _sectionLabel(context.l10n.profileSectionPersonal),
              if (showEditProfile)
                _menuItem(
                  context,
                  icon: Icons.person_outline,
                  title: context.l10n.profileEdit,
                  onTap: () async {
                    if (!await AuthController.ensureLoggedIn(context)) return;
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
              _menuItem(
                context,
                icon: Icons.translate,
                title: context.l10n.profileLanguage,
                // Ngôn ngữ đang chọn (trước đây ghi cứng "Tiếng Việt").
                trailingText: LanguageController.nativeName(
                  LanguageController.instance.code,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
              ),
              _menuItem(
                context,
                icon: Icons.history,
                title: context.l10n.historyTitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _sectionLabel(context.l10n.profileSectionDevice),
              _beaconScanItem(context),
              const SizedBox(height: 16),
          _sectionLabel(context.l10n.profileSectionSupport),
          _menuItem(
            context,
            icon: Icons.rate_review_outlined,
            title: context.l10n.profileRateSite,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            ),
          ),
          _menuItem(
            context,
            icon: Icons.notifications_outlined,
            title: context.l10n.profileNotifications,
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeThumbColor: AppColors.primary,
            ),
          ),
          _menuItem(
            context,
            icon: Icons.help_outline,
            title: context.l10n.profileHelpFaq,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          _menuItem(
            context,
            icon: Icons.info_outline,
            title: context.l10n.profileAbout,
            trailingText: AppInfo.versionLabel,
            onTap: linkAbout
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    )
                : () {},
          ),
              const SizedBox(height: 24),
              if (isLoggedIn)
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(
                        color: AppColors.danger, width: 1.2),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(context.l10n.logout),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final auth = AuthController.instance;
    // Khách và người đã đăng nhập dùng hai card khác nhau hẳn: card guest
    // không có avatar rỗng, mà nói rõ đăng nhập thì được gì.
    return auth.isLoggedIn ? _loggedInCard(context, auth) : _guestCard(context);
  }

  Widget _loggedInCard(BuildContext context, AuthController auth) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mint, width: 2),
            ),
            child: const Icon(Icons.person, size: 36, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: _loggedInInfo(context, auth)),
        ],
      ),
    );
  }

  Widget _loggedInInfo(BuildContext context, AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auth.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          auth.email,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium,
                  size: 14, color: Color(0xFFFFD97D)),
              const SizedBox(width: 4),
              Text(
                context.l10n.profileBadge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.person_outline,
                    size: 30, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.l10n.profileGuestTitle,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AuthController.ensureLoggedIn(context),
                  child: Text(context.l10n.login),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(context.l10n.register),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Công tắc quét iBeacon — dùng chung state với sidebar và card trang chủ,
  /// nên bật ở đây thì hai chỗ kia cũng đổi theo.
  Widget _beaconScanItem(BuildContext context) {
    return ListenableBuilder(
      listenable: BeaconScanController.instance,
      builder: (context, _) {
        final scanning = BeaconScanController.instance.isScanning;
        return _menuItem(
          context,
          icon: scanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
          title: context.l10n.profileBeaconScan,
          trailingText: scanning
              ? context.l10n.homeScanning
              : context.l10n.profileScanOff,
          trailing: Switch(
            value: scanning,
            onChanged: (_) => toggleBeaconScan(context),
            activeThumbColor: AppColors.primary,
          ),
          onTap: () => toggleBeaconScan(context),
        );
      },
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    trailingText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              trailing ??
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Giữ sẵn messenger và navigator: dialogContext chết ngay sau
              // pop, mà logout thì còn phải chờ mạng. Lấy trước cả hai để
              // không chạm vào BuildContext sau await.
              final messenger = ScaffoldMessenger.of(dialogContext);
              final loggedOut = context.l10n.loggedOut;
              final navigator = Navigator.of(context);
              Navigator.of(dialogContext).pop();
              // Đăng xuất về chế độ khách, vẫn ở trong app.
              await AuthController.instance.logout();
              // Về trang chủ. Đăng xuất xong mà còn đứng ở trang tài khoản
              // rỗng thì vô nghĩa; popUntil dọn luôn cả route chồng lên nếu
              // khách đi sâu hơn. Ở bản V1 trang này là tab trong IndexedStack
              // chứ không phải route, nên popUntil là no-op và tab giữ nguyên.
              navigator.popUntil((route) => route.isFirst);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(loggedOut)),
                );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }
}
