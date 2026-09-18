import 'package:flutter/material.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';
import '../artifact/artifact_detail_screen.dart';

/// Danh sách thông báo, mở từ nút chuông ở header trang chủ.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NotificationController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) => TextButton(
              onPressed: store.unreadCount == 0 ? null : store.markAllRead,
              child: const Text('Đánh dấu đã đọc'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.isEmpty) return const _EmptyNotifications();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: store.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = store.items[i];
              return _NotificationTile(
                notification: item,
                read: store.isRead(item.id),
                onTap: () => _open(context, item),
              );
            },
          );
        },
      ),
    );
  }

  void _open(BuildContext context, AppNotification item) {
    NotificationController.instance.markRead(item.id);
    final artifactId = item.artifactId;
    if (artifactId == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ArtifactDetailScreen(artifact: ArtifactRepository.instance.byId(artifactId)),
    ));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.read,
    required this.onTap,
  });

  final AppNotification notification;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Chưa đọc: nền phớt nâu đỏ + chấm ở góc, để phân biệt ngay khi quét mắt.
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppColors.background : AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon, color: _tint, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                read ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!read) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        notification.timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (notification.artifactId != null) ...[
                        const Spacer(),
                        const Text(
                          'Xem hiện vật',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (notification.kind) {
        AppNotificationKind.beacon => Icons.bluetooth_searching,
        AppNotificationKind.artifact => Icons.museum_outlined,
        AppNotificationKind.event => Icons.event_outlined,
        AppNotificationKind.feedback => Icons.mark_email_read_outlined,
      };

  Color get _tint => switch (notification.kind) {
        AppNotificationKind.beacon => AppColors.primary,
        AppNotificationKind.artifact => AppColors.accent,
        AppNotificationKind.event => AppColors.primaryLight,
        AppNotificationKind.feedback => AppColors.success,
      };
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

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
              child: const Icon(Icons.notifications_off_outlined,
                  size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thông báo về hiện vật gần bạn và sự kiện\nở khu di tích sẽ hiện ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
