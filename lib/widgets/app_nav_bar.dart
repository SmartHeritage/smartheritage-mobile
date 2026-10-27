import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Tên tab — không hiện chữ trên thanh, chỉ dùng cho trình đọc màn hình.
  final String label;

  /// Số chấm đỏ trên icon (vd. thông báo chưa đọc); 0 thì không hiện.
  final int badgeCount;
}

/// Nút tròn ở giữa thanh (vd. nút quét).
class AppNavCenterButton {
  const AppNavCenterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Tên cho trình đọc màn hình (nút chỉ có icon).
  final String label;
  final VoidCallback onTap;
}

/// Thanh điều hướng dưới, nền trắng nằm sát đáy màn hình như `NavigationBar` cũ —
/// mini-player đặt ngay trên nó thành một khối liền.
///
/// Giữ từ bản trước: chỉ icon (không chữ chú thích), khối chọn trượt sang tab mới,
/// icon đang chọn phóng nhẹ.
///
/// Nút giữa ([centerButton]) có hai dạng, chuyển qua lại có hoạt ảnh: [raiseCenter]
/// thì to và trồi lên khỏi mép trên thanh; không thì nhỏ, nằm gọn trong thanh — dùng
/// khi mini-player đang hiện ngay trên thanh, để nút không đè lên nó. Dạng trồi lên
/// cần Scaffold bật `extendBody` (dải trồi lên trong suốt, thấy nội dung phía sau).
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerButton,
    this.raiseCenter = false,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Có thì chen vào giữa hai nửa [items].
  final AppNavCenterButton? centerButton;

  /// Nút giữa to và trồi lên khỏi thanh (xem mô tả lớp).
  final bool raiseCenter;

  static const double _height = 70;

  /// Khối chọn sau icon: gần vuông, bo góc (không dẹt ngang kiểu viên thuốc).
  static const double _indicatorWidth = 60;
  static const double _indicatorHeight = 54;
  static const double _indicatorRadius = 22;

  /// Nút giữa nằm trong thanh: đường kính, khoảng chừa giữa hai nửa tab.
  static const double _centerSize = 52;
  static const double _centerGap = 76;

  /// Nút giữa trồi lên: đường kính, phần nhô trên mép thanh, khoảng chừa.
  static const double _raisedSize = 70;
  static const double _raisedRise = 24;
  static const double _raisedGap = 82;

  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final center = centerButton;
    final bottomInset = _bottomInset(context);
    if (center == null) return _bar(gap: 0, bottomInset: bottomInset);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: raiseCenter ? 1 : 0),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final rise = _raisedRise * t;
        final size = lerpDouble(_centerSize, _raisedSize, t)!;
        // Tâm nút tính từ mép trên dải trồi lên: trong thanh thì ở giữa thanh,
        // trồi lên thì mép trên nút chạm mép trên dải.
        final centerY = lerpDouble(rise + _height / 2, _raisedSize / 2, t)!;
        // Nút phải nằm trong khung widget này mới bấm được (phần vẽ tràn ra ngoài
        // khung không nhận chạm), nên dải trồi lên là một phần của thanh. Chỗ trống
        // hai bên nút trong dải vẫn để lọt cú chạm xuống nội dung bên dưới.
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: rise),
              child: _bar(
                gap: lerpDouble(_centerGap, _raisedGap, t)!,
                bottomInset: bottomInset,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: centerY - size / 2,
              child: Center(
                child: _CenterButton(button: center, size: size, raised: t),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Lề dưới icon. Máy có thanh home (iPhone không nút) thì cho icon lấn xuống vùng
  /// an toàn một đoạn như tab bar iOS — chừa nguyên vùng đó (34pt) thì khoảng trắng
  /// dưới icon quá nhiều; máy không có thì sát đáy, chỉ chừa một chút.
  static double _bottomInset(BuildContext context) {
    final system = MediaQuery.viewPaddingOf(context).bottom;
    return system > 0 ? math.max(system - 14, 8) : 4;
  }

  /// Thanh trắng với các tab; [gap] là khoảng chừa ở giữa cho nút giữa.
  Widget _bar({required double gap, required double bottomInset}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // Nền trắng phủ xuống tận đáy màn hình; icon nằm trên [bottomInset].
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - gap) / items.length;
              // Nửa sau của các tab nằm bên phải khoảng chừa cho nút giữa.
              final half = (items.length / 2).ceil();
              final selectedLeft =
                  currentIndex * itemWidth + (currentIndex >= half ? gap : 0);
              return Stack(
                children: [
                  // Khối chọn trượt theo tab đang chọn.
                  AnimatedPositioned(
                    duration: _duration,
                    curve: Curves.easeOutCubic,
                    left: selectedLeft + (itemWidth - _indicatorWidth) / 2,
                    top: (_height - _indicatorHeight) / 2,
                    width: _indicatorWidth,
                    height: _indicatorHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(_indicatorRadius),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (gap > 0 && i == half) SizedBox(width: gap),
                        Expanded(
                          child: _NavButton(
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
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.button,
    required this.size,
    required this.raised,
  });

  final AppNavCenterButton button;
  final double size;

  /// 0 = nằm trong thanh, 1 = trồi lên (viền trắng tách nút khỏi nội dung phía sau).
  final double raised;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: button.label,
      excludeSemantics: true,
      // Màu, viền và bóng vẽ bằng DecoratedBox ngoài cùng — không vẽ qua `Ink`:
      // Ink chỉ vẽ trong khung chữ nhật của Material nên bóng đổ bị cắt thành một
      // mảng vuông mờ sau nút. Hiệu ứng bấm thì cắt tròn bằng ClipOval.
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
          border: raised > 0
              ? Border.all(color: Colors.white, width: 4 * raised)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(
                alpha: lerpDouble(0.30, 0.35, raised)!,
              ),
              blurRadius: lerpDouble(10, 18, raised)!,
              offset: Offset(0, lerpDouble(4, 8, raised)!),
            ),
          ],
        ),
        child: ClipOval(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: button.onTap,
              child: Center(
                child: Icon(
                  button.icon,
                  size: lerpDouble(26, 32, raised),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      // Chấm số chỉ là hình — đọc thêm con số cho trình đọc màn hình.
      value: item.badgeCount > 0 ? '${item.badgeCount}' : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Chỉ icon, không chữ chú thích (theo yêu cầu); tên tab vẫn đọc được
        // qua Semantics ở trên cho trình đọc màn hình.
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1,
            duration: AppNavBar._duration,
            curve: Curves.easeOutBack,
            child: Badge(
              isLabelVisible: item.badgeCount > 0,
              backgroundColor: AppColors.danger,
              label: Text(item.badgeCount > 9 ? '9+' : '${item.badgeCount}'),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 30,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
