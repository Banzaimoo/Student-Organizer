import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/fill_scroll.dart';
import '../../../core/widgets/skeleton_list.dart';
import '../data/note.dart';
import '../providers/note_provider.dart';
import 'note_actions.dart';
import 'widgets/note_card.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NoteProvider>();
      if (!provider.hasLoaded) provider.load();
    });
  }

  void _openNew() => pushForMessage(context, '/notes/new');

  Future<void> _delete(Note n) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await deleteNote(context, n)) {
      messenger.showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
    }
  }

  /// Pull-to-refresh. Keeps the current list on failure and says why.
  Future<void> _refresh() async {
    final provider = context.read<NoteProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.load();
    if (provider.error != null && provider.hasLoaded) {
      messenger.showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    final hasNotes = provider.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          if (hasNotes)
            IconButton(
              tooltip: provider.gridView ? 'Tampilan daftar' : 'Tampilan grid',
              onPressed: provider.toggleView,
              icon: Icon(
                provider.gridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_outlined,
              ),
            ),
        ],
      ),
      // The first-run empty state carries its own add button; avoid two CTAs.
      floatingActionButton: hasNotes
          ? FloatingActionButton.extended(
              onPressed: _openNew,
              icon: const Icon(Icons.add),
              label: const Text('Tambah catatan'),
            )
          : null,
      body: Column(
        children: [
          if (hasNotes) _Filters(provider: provider),
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

  Widget _body(NoteProvider provider) {
    if (provider.loading && !provider.hasLoaded) return const SkeletonList();
    if (provider.error != null && !provider.hasLoaded) {
      return FillScroll(
        child: ErrorView(message: provider.error!, onRetry: provider.load),
      );
    }
    if (provider.items.isEmpty) {
      return FillScroll(
        child: EmptyState(
          icon: Icons.sticky_note_2_outlined,
          title: 'Belum ada catatan',
          message:
              'Simpan ringkasan materi kuliah di sini supaya mudah dibaca '
              'ulang saat belajar.',
          actionLabel: 'Tambah catatan',
          onAction: _openNew,
        ),
      );
    }
    final notes = provider.visible;
    if (notes.isEmpty) {
      return const FillScroll(
        child: EmptyState(
          icon: Icons.search_off,
          title: 'Tidak ada catatan yang cocok',
          message: 'Coba kata kunci atau mata kuliah lain.',
        ),
      );
    }

    Widget card(Note n, {bool fill = false}) => NoteCard(
      key: ValueKey(n.id),
      note: n,
      fill: fill,
      onTap: () => pushForMessage(context, '/notes/${n.id}'),
      onEdit: () => pushForMessage(context, '/notes/${n.id}/edit'),
      onDelete: () => _delete(n),
    );

    // Bottom padding keeps the last card clear of the FAB.
    const padding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      96,
    );

    if (!provider.gridView) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.listMaxWidth),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => card(notes[i]),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.gridMaxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 2 columns on phones, 3–4 on wider screens (FR-NOTE-01).
            final w = constraints.maxWidth;
            final columns = w < 600 ? 2 : (w < 960 ? 3 : 4);
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                // Fixed height fits title, course, 3-line snippet and footer;
                // scaled so larger system text does not clip.
                mainAxisExtent: MediaQuery.textScalerOf(context).scale(188),
              ),
              itemCount: notes.length,
              itemBuilder: (_, i) => card(notes[i], fill: true),
            );
          },
        ),
      ),
    );
  }
}

/// Search box plus per-course chips (FR-NOTE-04).
class _Filters extends StatefulWidget {
  const _Filters({required this.provider});

  final NoteProvider provider;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late final _search = TextEditingController(text: widget.provider.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final courses = provider.courses;

    Widget chip(String label, String? courseId) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        selected: provider.courseFilter == courseId,
        onSelected: (_) => provider.setCourseFilter(courseId),
        label: Text(label),
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.gridMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _search,
                onChanged: provider.setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari judul atau isi catatan',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: provider.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            provider.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            // A single course is not worth filtering by, unless a filter is
            // still on and needs a way off.
            if (courses.length > 1 || provider.courseFilter != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    chip('Semua', null),
                    for (final e in courses.entries) chip(e.value, e.key),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
