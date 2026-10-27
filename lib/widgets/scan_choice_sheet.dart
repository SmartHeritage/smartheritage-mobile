import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../screens/scan/beacon_scan_screen.dart';
import '../screens/scan/qr_scan_screen.dart';
import '../state/auth_state.dart';
import '../state/beacon_scan_state.dart';
import '../theme/app_theme.dart';

/// Bảng chọn của nút quét giữa thanh điều hướng: quét mã QR hoặc sang trang
/// quét beacon ([BeaconScanScreen]).
///
/// Quét QR và quét beacon đều phải đăng nhập (2026-10-21) — hỏi ngay khi bấm
/// nút quét, khỏi để khách chọn xong mới bị chặn.
Future<void> showScanChoiceSheet(BuildContext context) async {
  if (!await AuthController.ensureLoggedIn(context)) return;
  if (!context.mounted) return;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.scanSheetTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _ScanOption(
              icon: Icons.qr_code_scanner,
              title: context.l10n.scanQrTitle,
              subtitle: context.l10n.scanQrSubtitle,
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const QrScanScreen()));
              },
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: BeaconScanController.instance,
              builder: (_, _) {
                final scanning = BeaconScanController.instance.isScanning;
                return _ScanOption(
                  icon: Icons.bluetooth_searching,
                  title: context.l10n.scanBeaconTitle,
                  subtitle: scanning
                      ? context.l10n.scanBeaconActive
                      : context.l10n.scanBeaconIdle,
                  active: scanning,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // Trang riêng tự bật quét khi mở; bật/tắt ở nút giữa trang.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BeaconScanScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ScanOption extends StatelessWidget {
  const _ScanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Beacon đang quét — tô nổi để khách biết đang bật.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.surfaceTint : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
