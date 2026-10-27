import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/back_or_home.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/schedule.dart';
import '../providers/schedule_provider.dart';
import 'schedule_actions.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({super.key, required this.id});

  final String id;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  /// Used only when the page is opened by deep link before the list loaded.
  Schedule? _fetched;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScheduleProvider>();
    if (provider.byId(widget.id) == null) {
      _fetching = true;
      provider.fetch(widget.id).then((s) {
        if (!mounted) return;
        setState(() {
          _fetched = s;
          _fetching = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    // Prefer the live provider copy so edits show up immediately.
    final s = provider.byId(widget.id) ?? _fetched;

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(fallback: '/schedules'),
        title: const Text('Detail jadwal'),
      ),
      body: _fetching
          ? const LoadingView()
          : s == null
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Jadwal tidak ditemukan',
                  message: 'Jadwal ini mungkin sudah dihapus.',
                )
              : _content(context, provider, s),
    );
  }

  Widget _content(BuildContext context, ScheduleProvider provider, Schedule s) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final clashes = provider.clashesWith(s);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '${DateFormatter.dayName(s.dayOfWeek)} · ${s.timeRange}',
              style: text.labelLarge?.copyWith(
                color: scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(s.courseName, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Hari',
                    value: DateFormatter.dayName(s.dayOfWeek),
                  ),
                  const Divider(indent: 56),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Jam',
                    value: s.timeRange,
                  ),
                  const Divider(indent: 56),
                  _InfoRow(
                    icon: Icons.meeting_room_outlined,
                    label: 'Ruangan',
                    value: s.room,
                  ),
                  const Divider(indent: 56),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Dosen',
                    value: s.lecturer,
                  ),
                ],
              ),
            ),
            if (clashes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _ClashLine(clashes: clashes),
            ],
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
                      // Keep showing this schedule while the page closes.
                      _fetched = s;
                      if (await deleteSchedule(context, s) && context.mounted) {
                        closeWithMessage(context, 'Jadwal dihapus', '/schedules');
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
                        pushForMessage(context, '/schedules/${s.id}/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit jadwal'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        style: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}

class _ClashLine extends StatelessWidget {
  const _ClashLine({required this.clashes});

  final List<Schedule> clashes;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final names =
        clashes.map((c) => '${c.courseName} (${c.timeRange})').join(', ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.onWarningContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Bentrok dengan $names.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onWarningContainer),
            ),
          ),
        ],
      ),
    );
  }
}
