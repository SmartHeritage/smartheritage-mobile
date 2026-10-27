import 'package:flutter/material.dart';

import '../../data/news_repository.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_state.dart';
import '../../state/news_inbox_state.dart';
import '../../theme/app_theme.dart';
import '../news/news_detail_screen.dart';

/// Tab Thông báo của bản V2 (thay tab Yêu thích, 2026-10-21): bài viết ban
/// quản lý đăng ở admin, bài mới có chấm đỏ. Phải đăng nhập mới nhận.
///
/// Khác `NotificationScreen` của V1 (chuông, dữ liệu mẫu) — màn đó giữ nguyên.
class NewsInboxScreen extends StatelessWidget {
  const NewsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = NewsInboxController.instance;
    return ListenableBuilder(
      listenable: inbox,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.inboxTitle),
            actions: [
              if (inbox.unreadCount > 0)
                IconButton(
                  tooltip: context.l10n.inboxMarkAllRead,
                  onPressed: inbox.markAllRead,
                  icon: const Icon(Icons.done_all),
                ),
            ],
          ),
          body: inbox.isLoggedIn
              ? _InboxList(inbox: inbox)
              : const _LoginPrompt(),
        );
      },
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({required this.inbox});

  final NewsInboxController inbox;

  @override
  Widget build(BuildContext context) {
    final items = inbox.items;
    if (items.isEmpty && inbox.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final bottom = 24 + MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: inbox.refresh,
      child: items.isEmpty
          // Vẫn kéo xuống được để tải lại khi admin vừa đăng bài.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(32, 120, 32, bottom),
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 56,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.inboxEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return _InboxTile(
                  item: item,
                  unread: inbox.isUnread(item),
                  onTap: () {
                    inbox.markRead(item);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(item: item),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.item,
    required this.unread,
    required this.onTap,
  });

  final NewsItem item;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // Bài chưa đọc nền phớt màu như hộp thư, đọc rồi về trắng.
          color: unread ? AppColors.surfaceTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: NewsCover(item: item, height: 72),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.3,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (unread) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n.inboxNew,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.dateLabel.isNotEmpty)
                        Text(
                          item.dateLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
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
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.inboxLoginTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.inboxLoginMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
