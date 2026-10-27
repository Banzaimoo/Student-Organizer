import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/fill_scroll.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_list.dart';
import '../data/task.dart';
import '../providers/task_provider.dart';
import 'task_actions.dart';
import 'widgets/task_card.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      if (!provider.hasLoaded) provider.load();
    });
  }

  void _openNew() => pushForMessage(context, '/tasks/new');

  Future<void> _delete(Task t) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await deleteTask(context, t)) {
      messenger.showSnackBar(const SnackBar(content: Text('Tugas dihapus')));
    }
  }

  /// Pull-to-refresh. Keeps the current list on failure and says why.
  Future<void> _refresh() async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.load();
    if (provider.error != null && provider.hasLoaded) {
      messenger.showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    // The first-run empty state carries its own add button; avoid two CTAs.
    final showFab = provider.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Tugas')),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _openNew,
              icon: const Icon(Icons.add),
              label: const Text('Tambah tugas'),
            )
          : null,
      body: Column(
        children: [
          _StatusFilter(provider: provider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _body(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(TaskProvider provider) {
    if (provider.loading && !provider.hasLoaded) return const SkeletonList();
    if (provider.error != null && !provider.hasLoaded) {
      return FillScroll(
        child: ErrorView(message: provider.error!, onRetry: provider.load),
      );
    }
    if (provider.items.isEmpty) {
      return FillScroll(
        child: EmptyState(
          icon: Icons.task_alt_outlined,
          title: 'Belum ada tugas',
          message:
              'Catat tugas kuliah beserta deadline-nya supaya tidak ada '
              'yang terlewat.',
          actionLabel: 'Tambah tugas',
          onAction: _openNew,
        ),
      );
    }
    final visible = provider.visible;
    if (visible.isEmpty) {
      final status = provider.statusFilter!;
      return FillScroll(
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'Tidak ada tugas berstatus ${status.label}',
          message: 'Pilih filter lain untuk melihat tugas lainnya.',
        ),
      );
    }

    // Already sorted by Task.compare: unfinished by deadline, then finished.
    final now = DateTime.now();
    final sections = <(String, List<Task>)>[
      ('Terlambat', visible.where((t) => t.isOverdue(now)).toList()),
      (
        'Belum selesai',
        visible.where((t) => !t.isDone && !t.isOverdue(now)).toList(),
      ),
      ('Selesai', visible.where((t) => t.isDone).toList()),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.listMaxWidth),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Bottom padding keeps the last card clear of the FAB.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            96,
          ),
          children: [
            for (final (title, tasks) in sections)
              if (tasks.isNotEmpty) ...[
                SectionHeader(
                  title: title,
                  trailing: Text(
                    '${tasks.length} tugas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final t in tasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TaskCard(
                      key: ValueKey(t.id),
                      task: t,
                      onTap: () => pushForMessage(context, '/tasks/${t.id}'),
                      onToggleDone: () => toggleTaskDone(context, t),
                      onEdit: () =>
                          pushForMessage(context, '/tasks/${t.id}/edit'),
                      onDelete: () => _delete(t),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

/// Semua / Belum / Sedang / Selesai, each with its count (FR-TASK-04).
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TaskStatus? status) {
      final count = provider.hasLoaded ? ' ${provider.count(status)}' : '';
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          selected: provider.statusFilter == status,
          onSelected: (_) => provider.setStatusFilter(status),
          label: Text('$label$count'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          chip('Semua', null),
          for (final s in TaskStatus.values) chip(s.label, s),
        ],
      ),
    );
  }
}
