import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/fill_scroll.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_list.dart';
import '../../courses/providers/course_provider.dart';
import '../data/schedule.dart';
import '../providers/schedule_provider.dart';
import 'schedule_actions.dart';
import 'widgets/schedule_tile.dart';

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ScheduleProvider>();
      if (!provider.hasLoaded) provider.load();
      context.read<CourseProvider>().load();
    });
  }

  void _openNew([int? day]) => pushForMessage(
      context, day == null ? '/schedules/new' : '/schedules/new?day=$day');

  Future<void> _delete(Schedule s) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await deleteSchedule(context, s)) {
      messenger.showSnackBar(const SnackBar(content: Text('Jadwal dihapus')));
    }
  }

  /// Pull-to-refresh. Keeps the current list on failure and says why.
  Future<void> _refresh() async {
    final provider = context.read<ScheduleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.load();
    if (provider.error != null && provider.hasLoaded) {
      messenger.showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    // Empty states carry their own add button; avoid two competing CTAs.
    final showFab = provider.grouped.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kuliah')),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _openNew(provider.dayFilter),
              icon: const Icon(Icons.add),
              label: const Text('Tambah jadwal'),
            )
          : null,
      body: Column(
        children: [
          _DayFilter(
            selected: provider.dayFilter,
            onSelected: provider.setDayFilter,
          ),
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

  Widget _body(ScheduleProvider provider) {
    if (provider.loading && !provider.hasLoaded) return const SkeletonList();
    if (provider.error != null && !provider.hasLoaded) {
      return FillScroll(
        child: ErrorView(message: provider.error!, onRetry: provider.load),
      );
    }
    if (provider.items.isEmpty) {
      return FillScroll(
        child: EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'Belum ada jadwal',
          message: 'Tambahkan mata kuliah yang kamu ambil semester ini. '
              'Nama mata kuliahnya juga akan tersedia di Tugas dan Catatan.',
          actionLabel: 'Tambah jadwal',
          onAction: _openNew,
        ),
      );
    }
    final groups = provider.grouped;
    if (groups.isEmpty) {
      final day = DateFormatter.dayName(provider.dayFilter!);
      return FillScroll(
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: 'Tidak ada kuliah hari $day',
          message: 'Pilih hari lain, atau tambahkan jadwal untuk hari $day.',
          actionLabel: 'Tambah jadwal $day',
          onAction: () => _openNew(provider.dayFilter),
        ),
      );
    }

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    bool isNow(Schedule s) =>
        s.dayOfWeek == now.weekday &&
        s.startMinutes <= nowMinutes &&
        nowMinutes < s.endMinutes;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.listMaxWidth),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Bottom padding keeps the last row clear of the FAB.
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, 96),
          children: [
            for (final entry in groups.entries) ...[
              SectionHeader(
                title: DateFormatter.dayName(entry.key),
                badge: entry.key == now.weekday ? 'Hari ini' : null,
                trailing: Text(
                  '${entry.value.length} kelas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              ScheduleGroup(
                children: [
                  for (final s in entry.value)
                    ScheduleTile(
                      schedule: s,
                      isNow: isNow(s),
                      onTap: () => pushForMessage(context, '/schedules/${s.id}'),
                      onEdit: () =>
                          pushForMessage(context, '/schedules/${s.id}/edit'),
                      onDelete: () => _delete(s),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Semua, Senin … Minggu. Today's chip carries a small dot.
class _DayFilter extends StatelessWidget {
  const _DayFilter({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday;

    Widget chip(String label, int? day) {
      final isSelected = selected == day;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onSelected(day),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (day == today) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.onSecondaryContainer
                        : scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          chip('Semua', null),
          for (var d = 1; d <= 7; d++) chip(DateFormatter.dayName(d), d),
        ],
      ),
    );
  }
}
