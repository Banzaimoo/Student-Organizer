import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/widgets/back_or_home.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/task.dart';
import '../providers/task_provider.dart';
import 'task_actions.dart';
import 'widgets/task_status_chip.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.id});

  final String id;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  /// Used only when the page is opened by deep link before the list loaded.
  Task? _fetched;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TaskProvider>();
    if (provider.byId(widget.id) == null) {
      _fetching = true;
      provider.fetch(widget.id).then((t) {
        if (!mounted) return;
        setState(() {
          _fetched = t;
          _fetching = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    // Prefer the live provider copy so edits show up immediately.
    final t = provider.byId(widget.id) ?? _fetched;

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(fallback: '/tasks'),
        title: const Text('Detail tugas'),
      ),
      body: _fetching
          ? const LoadingView()
          : t == null
          ? const EmptyState(
              icon: Icons.search_off,
              title: 'Tugas tidak ditemukan',
              message: 'Tugas ini mungkin sudah dihapus.',
            )
          : _content(context, t),
    );
  }

  Widget _content(BuildContext context, Task t) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final overdue = t.isOverdue();
    final description = t.description?.trim() ?? '';

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TaskStatusChip(status: t.status),
                if (overdue) const OverdueChip(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(t.title, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Mata kuliah',
                    value: t.courseName ?? 'Tanpa mata kuliah',
                  ),
                  const Divider(indent: 56),
                  InfoRow(
                    icon: Icons.event_outlined,
                    label: overdue ? 'Deadline (terlewat)' : 'Deadline',
                    value:
                        '${DateFormatter.date(t.deadline)} · '
                        '${DateFormatter.time(TimeOfDay.fromDateTime(t.deadline))}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Status', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<TaskStatus>(
              segments: [
                for (final s in TaskStatus.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {t.status},
              showSelectedIcon: false,
              onSelectionChanged: (v) => changeTaskStatus(context, t, v.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Deskripsi', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description.isEmpty ? 'Tidak ada deskripsi.' : description,
              style: text.bodyLarge?.copyWith(
                color: description.isEmpty ? scheme.onSurfaceVariant : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: () async {
                      // Keep showing this task while the page closes.
                      _fetched = t;
                      if (await deleteTask(context, t) && context.mounted) {
                        closeWithMessage(context, 'Tugas dihapus', '/tasks');
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        pushForMessage(context, '/tasks/${t.id}/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit tugas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
