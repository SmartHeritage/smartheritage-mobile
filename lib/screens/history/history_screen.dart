import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../l10n/l10n.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Lượt ghé do POST /scans ghi ở nơi khác → mỗi lần mở màn hỏi lại số liệu.
    VisitHistoryController.instance.refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    final store = VisitHistoryController.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.historyTitle),
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
              _StatsRow(stats: store.stats),
              const SizedBox(height: 18),
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
                    subtitle: context.l10n.historyDetectedAt(record.timeLabel),
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
        title: Text(context.l10n.historyClearTitle),
        content: Text(VisitHistoryController.instance.isAccountHistory
            ? context.l10n.historyClearAccount
            : context.l10n.historyClearDevice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              VisitHistoryController.instance.clear();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}

/// Ba ô thống kê đầu danh sách (`GET /visits/stats` khi đăng nhập).
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final VisitStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.museum_outlined,
            value: stats.artifactsViewed,
            label: context.l10n.historyStatArtifacts,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.event_available_outlined,
            value: stats.visitDays,
            label: context.l10n.historyStatDays,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.place_outlined,
            value: stats.attractionsVisited,
            label: context.l10n.historyStatAreas,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            Text(
              context.l10n.historyEmptyTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.historyEmptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
