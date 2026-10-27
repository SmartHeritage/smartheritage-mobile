import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';

/// Trang Giới thiệu, mở từ ô Giới thiệu ở lưới trang chủ V2 (2026-10-21).
///
/// Bố cục theo trang chi tiết hiện vật — banner co lại khi cuộn, khối tên bo
/// góc trượt lên trên banner, nút ← tròn — nhưng chỉ có banner và chữ. Backend
/// không có chỗ cấu hình phần giới thiệu nên nội dung viết sẵn trong file ARB.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Bo hai góc trên của khối tên, giống trang chi tiết hiện vật.
  static const double _headerRadius = 22;

  /// Khối tên luôn một dòng tên + một dòng mô tả ngắn nên cao cố định, không
  /// phải đo chữ như trang hiện vật (tên hiện vật dài ngắn tuỳ admin).
  static const double _titleHeight = 84;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240 + _titleHeight,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // Banner lấn xuống sau khối tên đúng bằng độ bo góc, để hai góc
              // bo lộ ảnh chứ không lộ nền.
              background: Padding(
                padding: const EdgeInsets.only(
                  bottom: _titleHeight - _headerRadius,
                ),
                // Cùng ảnh với thẻ đầu trang chủ; neo phải vì chủ thể (đền +
                // trống đồng) nằm sát mép phải ảnh.
                child: Image.asset(
                  'assets/images/hero_museum.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_titleHeight),
              child: Container(
                height: _titleHeight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_headerRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.aboutTagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 32 + MediaQuery.paddingOf(context).bottom),
            sliver: SliverList.list(
              children: [
                _Heading(l10n.aboutIntroHeading),
                _Paragraph(l10n.aboutIntroBody),
                const SizedBox(height: 22),
                _Heading(l10n.aboutFeaturesHeading),
                _Feature(Icons.museum_outlined, l10n.aboutFeatureDiscover),
                _Feature(Icons.headphones_outlined, l10n.aboutFeatureListen),
                _Feature(Icons.qr_code_scanner, l10n.aboutFeatureScan),
                _Feature(Icons.map_outlined, l10n.aboutFeatureMap),
                _Feature(
                    Icons.notifications_none_rounded, l10n.aboutFeatureNews),
                const SizedBox(height: 22),
                _Heading(l10n.aboutHowHeading),
                _Paragraph(l10n.aboutHowBody),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    l10n.aboutVersion(AppInfo.version),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.55,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Một dòng tính năng: icon tròn nền phớt màu + mô tả.
class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
