import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/widgets/back_or_home.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/note.dart';
import '../providers/note_provider.dart';
import 'note_actions.dart';

/// Swipe to the previous/next note with a [PageView] (FR-NOTE-05).
class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({super.key, required this.id});

  final String id;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  /// Page order, fixed when the page opens. Saving a note re-sorts the
  /// provider list by `updated_at`; reading pages from it directly would
  /// swap the note under the user after an edit.
  List<String> _ids = const [];

  /// Last known copy of each page's note, so a deleted note stays on screen
  /// while the page closes, and a deep-linked note outside the list shows.
  final _notes = <String, Note>{};

  PageController? _controller;
  int _index = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NoteProvider>();
    if (provider.byId(widget.id) != null) {
      _open(provider);
      return;
    }
    // Opened by deep link: load the list after this frame so swiping works.
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!provider.hasLoaded) await provider.load();
      if (provider.byId(widget.id) == null) {
        final n = await provider.fetch(widget.id);
        if (n != null) _notes[widget.id] = n;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _open(provider);
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Snapshots the order the user was looking at (filtered list first).
  void _open(NoteProvider provider) {
    var ids = [for (final n in provider.visible) n.id!];
    if (!ids.contains(widget.id)) ids = [for (final n in provider.items) n.id!];
    if (!ids.contains(widget.id)) ids = [widget.id];
    _ids = ids;
    _index = ids.indexOf(widget.id);
    _controller = PageController(initialPage: _index);
  }

  String get _currentId => _ids[_index];

  void _go(int delta) {
    final target = _index + delta;
    if (target < 0 || target >= _ids.length) return;
    _controller!.animateToPage(
      target,
      duration: AppMotion.normal,
      curve: AppMotion.curve,
    );
  }

  Future<void> _delete(Note n) async {
    if (await deleteNote(context, n) && mounted) {
      closeWithMessage(context, 'Catatan dihapus', '/notes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    for (final id in _ids) {
      final live = provider.byId(id);
      if (live != null) _notes[id] = live;
    }
    final current = _ids.isEmpty ? null : _notes[_currentId];

    // Arrow keys page too, wherever focus is on this page (even the pager).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
      },
      child: Focus(autofocus: true, child: _scaffold(context, current)),
    );
  }

  Widget _scaffold(BuildContext context, Note? current) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(fallback: '/notes'),
        title: const Text('Detail catatan'),
        actions: [
          if (current != null) ...[
            IconButton(
              tooltip: 'Edit catatan',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  pushForMessage(context, '/notes/${current.id}/edit'),
            ),
            IconButton(
              tooltip: 'Hapus catatan',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(current),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _ids.length > 1 && current != null
          ? _Pager(
              index: _index,
              count: _ids.length,
              onPrevious: () => _go(-1),
              onNext: () => _go(1),
            )
          : null,
      body: _loading
          ? const LoadingView()
          : current == null
          ? const EmptyState(
              icon: Icons.search_off,
              title: 'Catatan tidak ditemukan',
              message: 'Catatan ini mungkin sudah dihapus.',
            )
          // Mouse drag is off by default on web/desktop; allow it so
          // swiping works there too.
          : ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: PageView.builder(
                controller: _controller,
                itemCount: _ids.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final n = _notes[_ids[i]];
                  return n == null
                      ? const SizedBox.shrink()
                      : _NotePage(note: n);
                },
              ),
            ),
    );
  }
}

class _NotePage extends StatelessWidget {
  const _NotePage({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final n = note;
    final updated = n.updatedAt;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              n.courseName ?? 'Tanpa mata kuliah',
              style: text.labelLarge?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(n.title, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Tanggal catatan',
                    value: DateFormatter.date(n.noteDate),
                  ),
                  if (updated != null) ...[
                    const Divider(indent: 56),
                    InfoRow(
                      icon: Icons.update,
                      label: 'Terakhir diperbarui',
                      value:
                          '${DateFormatter.date(updated)} · '
                          '${DateFormatter.time(TimeOfDay.fromDateTime(updated))}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(n.content, style: text.bodyLarge?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}

/// Previous/next buttons with the position, for mouse and keyboard users.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Catatan sebelumnya',
                onPressed: index > 0 ? onPrevious : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  'Catatan ${index + 1} dari $count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Catatan berikutnya',
                onPressed: index < count - 1 ? onNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
