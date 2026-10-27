import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/note.dart';

/// `Diperbarui Hari ini`; falls back to the note date before the first save.
String updatedLabel(Note n, [DateTime? now]) => n.updatedAt == null
    ? DateFormatter.relativeDay(n.noteDate, now)
    : 'Diperbarui ${DateFormatter.relativeDay(n.updatedAt!, now)}';

/// One note: title, course, a 3-line snippet and when it was last edited
/// (FR-NOTE-02), plus a menu.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.fill = false,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// True in a grid cell of fixed height: the footer sticks to the bottom.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final n = note;

    final snippet = Text(
      n.content,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: text.bodySmall?.copyWith(color: scheme.onSurface, height: 1.4),
    );

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        n.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                  ),
                  _Menu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  n.courseName ?? 'Tanpa mata kuliah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: scheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (fill)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Align(alignment: Alignment.topLeft, child: snippet),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: snippet,
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.update, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      updatedLabel(n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<String>(
        tooltip: 'Opsi',
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text('Hapus', style: TextStyle(color: scheme.error)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
