import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../data/task.dart';

/// Grey for Belum, yellow for Sedang, green for Selesai (§6.1).
class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final (bg, fg) = switch (status) {
      TaskStatus.belum => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      TaskStatus.sedang => (colors.warningContainer, colors.onWarningContainer),
      TaskStatus.selesai => (
        colors.successContainer,
        colors.onSuccessContainer,
      ),
    };
    return _Pill(label: status.label, background: bg, foreground: fg);
  }
}

/// Red marker for unfinished tasks past their deadline (FR-TASK-03).
class OverdueChip extends StatelessWidget {
  const OverdueChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Pill(
      label: 'Terlambat',
      icon: Icons.error_outline,
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
