import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_info.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../feedback/feedback_screen.dart';

/// Trợ giúp & câu hỏi thường gặp.
///
/// Nội dung viết theo hành vi thật của app: công tắc quét nằm ở sidebar,
/// thuyết minh tự phát khi beacon phát hiện, khách không cần đăng nhập...
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Thay bằng thông tin liên hệ thật của khu di tích trước khi phát hành.
  static const _supportEmail = 'hotro@smartheritage.vn';
  static const _supportPhone = '1900 0000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          for (final group in _groups(context.l10n)) ...[
            _GroupCard(group: group),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          _contactCard(context),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Smart Heritage ${AppInfo.versionLabel}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.helpStillStuck,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.helpContactText,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _contactRow(
            context,
            icon: Icons.mail_outline,
            label: _supportEmail,
            copiedMessage: context.l10n.helpEmailCopied,
          ),
          const SizedBox(height: 10),
          _contactRow(
            context,
            icon: Icons.phone_outlined,
            label: _supportPhone,
            copiedMessage: context.l10n.helpPhoneCopied,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 20),
              label: Text(context.l10n.feedbackSend),
            ),
          ),
        ],
      ),
    );
  }

  /// Bấm để sao chép — app chưa có url_launcher nên không mở được app mail/gọi.
  Widget _contactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String copiedMessage,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: label));
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(copiedMessage)));
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.copy_rounded,
              size: 15, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final _FaqGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            color: AppColors.surfaceTint,
            child: Row(
              children: [
                Icon(group.icon, size: 19, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 16, endIndent: 16),
            _FaqRow(item: group.items[i]),
          ],
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    // Bỏ divider mặc định của ExpansionTile để dùng divider của _GroupCard.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        children: [
          Text(
            item.answer,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

class _FaqGroup {
  const _FaqGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_FaqItem> items;
}

/// Nội dung theo ngôn ngữ giao diện (lib/l10n/app_*.arb, khoá helpGroup*/helpQ*/helpA*).
List<_FaqGroup> _groups(AppLocalizations l10n) => [
  _FaqGroup(
    title: l10n.helpGroup1,
    icon: Icons.bluetooth_searching,
    items: [
      _FaqItem(l10n.helpQ1, l10n.helpA1),
      _FaqItem(l10n.helpQ2, l10n.helpA2),
      _FaqItem(l10n.helpQ3, l10n.helpA3),
      _FaqItem(l10n.helpQ4, l10n.helpA4),
    ],
  ),
  _FaqGroup(
    title: l10n.helpGroup2,
    icon: Icons.headphones_rounded,
    items: [
      _FaqItem(l10n.helpQ5, l10n.helpA5),
      _FaqItem(l10n.helpQ6, l10n.helpA6),
      _FaqItem(l10n.helpQ7, l10n.helpA7),
      _FaqItem(l10n.helpQ8, l10n.helpA8),
      _FaqItem(l10n.helpQ9, l10n.helpA9),
    ],
  ),
  _FaqGroup(
    title: l10n.helpGroup3,
    icon: Icons.person_outline,
    items: [
      _FaqItem(l10n.helpQ10, l10n.helpA10),
      _FaqItem(l10n.helpQ11, l10n.helpA11),
      _FaqItem(l10n.helpQ12, l10n.helpA12),
    ],
  ),
  _FaqGroup(
    title: l10n.helpGroup4,
    icon: Icons.map_outlined,
    items: [
      _FaqItem(l10n.helpQ13, l10n.helpA13),
      _FaqItem(l10n.helpQ14, l10n.helpA14),
      _FaqItem(l10n.helpQ15, l10n.helpA15),
    ],
  ),
  _FaqGroup(
    title: l10n.helpGroup5,
    icon: Icons.notifications_outlined,
    items: [
      _FaqItem(l10n.helpQ16, l10n.helpA16),
      _FaqItem(l10n.helpQ17, l10n.helpA17),
    ],
  ),
];
