import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Tên tab — không hiện chữ trên thanh, chỉ dùng cho trình đọc màn hình.
  final String label;
}

/// Nút tròn to nổi ở giữa thanh (vd. nút quét).
class GlassNavCenterButton {
  const GlassNavCenterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Tên cho trình đọc màn hình (nút chỉ có icon).
  final String label;
  final VoidCallback onTap;
}

/// Thanh điều hướng dưới dạng viên thuốc nổi, nền kính mờ — phỏng theo Liquid
/// Glass của iOS bằng `BackdropFilter` (làm mờ + viền sáng), không khúc xạ như
/// bản thật nhưng nhẹ và chạy giống nhau trên cả Android.
///
/// Muốn thấy "kính" thì nội dung phải chạy xuống dưới thanh: Scaffold chứa nó
/// bật `extendBody`, và màn hình bên trong cộng [MediaQuery.paddingOf] `.bottom`
/// vào lề dưới danh sách/thẻ nổi để phần cuối không bị thanh che.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerButton,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Có thì chen vào giữa hai nửa [items], nhô lên khỏi mép trên thanh.
  final GlassNavCenterButton? centerButton;

  static const double _height = 64;

  /// Nút giữa: đường kính, phần nhô lên trên mép thanh, khoảng chừa trong thanh.
  static const double _centerSize = 70;
  static const double _centerRise = 24;
  static const double _centerGap = 82;
  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    // Máy có thanh home (iPhone không nút) thì để thanh lấn xuống vùng an toàn
    // một chút như tab bar iOS 26; máy không có thì chừa lề cố định.
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bottom = systemBottom > 0 ? math.max(systemBottom - 10, 8.0) : 12.0;

    final center = centerButton;
    final pill = DecoratedBox(
      // Bóng nằm ngoài ClipRRect để không bị cắt mất.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_height / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_height / 2),
              // Trên sáng hơn dưới: giả vệt sáng phản chiếu trên mặt kính.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.78),
                  Colors.white.withValues(alpha: 0.58),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = center == null ? 0.0 : _centerGap;
                final itemWidth = (constraints.maxWidth - gap) / items.length;
                // Nửa sau của các tab nằm bên phải khoảng chừa cho nút giữa.
                final half = (items.length / 2).ceil();
                final selectedLeft =
                    currentIndex * itemWidth + (currentIndex >= half ? gap : 0);
                return Stack(
                  children: [
                    // Khối sáng trượt theo tab đang chọn.
                    AnimatedPositioned(
                      duration: _duration,
                      curve: Curves.easeOutCubic,
                      left: selectedLeft + 5,
                      top: 5,
                      bottom: 5,
                      width: itemWidth - 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(_height / 2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (center != null && i == half) SizedBox(width: gap),
                          Expanded(
                            child: _GlassNavButton(
                              item: items[i],
                              isSelected: i == currentIndex,
                              onTap: () => onTap(i),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
      child: center == null
          ? pill
          // Nút giữa nhô lên trên thanh, nhưng vẫn phải nằm trong khung của
          // widget này: phần vẽ tràn ra ngoài khung thì không bấm được. Chỗ
          // trống hai bên nút trong dải nhô lên vẫn để lọt cú chạm xuống nội
          // dung bên dưới (Stack không tự nhận chạm).
          : SizedBox(
              height: _height + _centerRise,
              child: Stack(
                children: [
                  Positioned(left: 0, right: 0, bottom: 0, child: pill),
                  Align(
                    alignment: Alignment.topCenter,
                    child: _CenterButton(button: center),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.button});

  final GlassNavCenterButton button;

  @override
  Widget build(BuildContext context) {
    const size = GlassNavBar._centerSize;
    return Semantics(
      button: true,
      label: button.label,
      excludeSemantics: true,
      // Màu, viền và bóng vẽ bằng DecoratedBox ngoài cùng — không vẽ qua `Ink`:
      // Ink chỉ vẽ trong khung chữ nhật của Material nên bóng đổ bị cắt thành
      // một mảng vuông mờ sau nút. Hiệu ứng bấm thì cắt tròn bằng ClipOval.
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primaryDark],
          ),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: button.onTap,
              child: Center(
                child: Icon(button.icon, size: 32, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Chỉ icon, không chữ chú thích (theo yêu cầu); tên tab vẫn đọc được
        // qua Semantics ở trên cho trình đọc màn hình.
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1,
            duration: GlassNavBar._duration,
            curve: Curves.easeOutBack,
            child: Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 27,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
