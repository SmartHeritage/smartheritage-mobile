import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VisitHistoryController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử tham quan'),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) => IconButton(
              onPressed: store.isEmpty ? null : () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final records = store.records;
          if (records.isEmpty) return const _EmptyHistory();

          // Nhóm theo ngày (giữ thứ tự mới nhất trước).
          final grouped = <String, List<VisitRecord>>{};
          for (final record in records) {
            grouped.putIfAbsent(record.dateLabel, () => []).add(record);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final record in entry.value) ...[
                  ArtifactListTile(
                    artifact: record.artifact,
                    subtitle: 'iBeacon phát hiện lúc ${record.timeLabel}',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Xoá lịch sử'),
        content: const Text('Xoá toàn bộ lịch sử tham quan trên thiết bị này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              VisitHistoryController.instance.clear();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
              child: const Icon(Icons.bluetooth_searching,
                  size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có lịch sử tham quan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi bạn đến gần một hiện vật, iBeacon sẽ\ntự động ghi lại vào đây',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
