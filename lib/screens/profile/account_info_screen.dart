import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

/// Tab "Thông tin tài khoản" của bản V2 (2026-10-21): chỉ xem họ tên, email, số
/// điện thoại — không sửa được (giới tính đã bỏ theo yêu cầu). Đăng xuất, đổi
/// ngôn ngữ… ở ô Cài đặt trang chủ (trang cá nhân cũ, đã bỏ mục chỉnh sửa).
class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accountInfoTitle)),
      body: ListenableBuilder(
        listenable: AuthController.instance,
        builder: (context, _) {
          final user = AuthController.instance.user;
          if (user == null) return const _LoginPrompt();
          return _Details(user: user);
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 32 + MediaQuery.paddingOf(context).bottom),
      children: [
        Center(
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mint, width: 2),
            ),
            child: const Icon(Icons.person, size: 56, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 28),
        _Field(
          label: l10n.fieldFullName,
          icon: Icons.person_outline,
          value: user.fullName,
        ),
        _Field(
          label: l10n.fieldEmail,
          icon: Icons.mail_outline,
          value: user.email,
        ),
        _Field(
          label: l10n.fieldPhone,
          icon: Icons.phone_outlined,
          value: user.phone,
        ),
      ],
    );
  }
}

/// Một trường chỉ đọc, dựng bằng [InputDecorator] để trông y như ô nhập ở trang
/// Chỉnh sửa thông tin nhưng không có con trỏ hay bàn phím.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.icon, this.value});

  final String label;
  final IconData icon;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final empty = text.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              // Nền trắng thay màu phớt kem mặc định của ô nhập — tab này nằm
              // trên ảnh nền tông kem (V2), ô kem sẽ chìm vào nền (2026-10-21).
              filled: true,
              fillColor: Colors.white,
            ),
            child: Text(
              // Trường trống (tài khoản mới chưa nhập) thì nói rõ thay vì để ô
              // trắng trông như lỗi tải.
              empty ? context.l10n.accountNotSet : text,
              style: TextStyle(
                fontSize: 15,
                color: empty ? AppColors.textSecondary : AppColors.textPrimary,
                fontStyle: empty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.accountLoginTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AuthController.ensureLoggedIn(context),
                icon: const Icon(Icons.login, size: 20),
                label: Text(context.l10n.loginOrRegister),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
