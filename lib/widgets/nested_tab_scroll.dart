import 'package:flutter/widgets.dart';

/// Sliver bù phần đầu ghim của [NestedScrollView] (trang chi tiết hiện vật: tên +
/// thanh tab ghim dưới thanh trên). Không có nó thì phần ghim đè lên đầu nội dung
/// tab — dòng đầu bị che, `ensureVisible` cuộn tới chỗ vẫn bị che.
///
/// Đặt đầu danh sách `slivers` của CustomScrollView trong mỗi tab:
/// `slivers: [...nestedOverlapInjector(context), …]`. Tab dùng ngoài
/// NestedScrollView thì trả rỗng.
List<Widget> nestedOverlapInjector(BuildContext context) {
  if (context.findAncestorWidgetOfExactType<NestedScrollView>() == null) {
    return const [];
  }
  return [
    SliverOverlapInjector(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
    ),
  ];
}
