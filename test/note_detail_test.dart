import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:student_organizer/core/theme/app_theme.dart';
import 'package:student_organizer/features/courses/data/course_repository.dart';
import 'package:student_organizer/features/courses/providers/course_provider.dart';
import 'package:student_organizer/features/notes/data/note.dart';
import 'package:student_organizer/features/notes/data/note_repository.dart';
import 'package:student_organizer/features/notes/presentation/note_detail_page.dart';
import 'package:student_organizer/features/notes/providers/note_provider.dart';

class _FakeCourses implements CourseRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeNotes implements NoteRepository {
  @override
  Future<List<Note>> fetchAll() async => [
    for (final (i, id) in ['satu', 'dua', 'tiga'].indexed)
      Note(
        id: id,
        courseId: 'bd',
        courseName: 'Basis Data',
        title: 'Catatan $id',
        content: 'Isi $id',
        noteDate: DateTime(2026, 10, 27),
        // satu is the newest, so the list order is satu, dua, tiga.
        updatedAt: DateTime(2026, 10, 27, 12 - i),
      ),
  ];

  @override
  Future<Note> update(Note n) async =>
      n.copyWith(updatedAt: DateTime(2026, 10, 28));

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  late NoteProvider provider;

  Future<void> pumpDetail(WidgetTester tester, String id) async {
    provider = NoteProvider(_FakeNotes(), CourseProvider(_FakeCourses()));
    await provider.load();
    final router = GoRouter(
      initialLocation: '/notes/$id',
      routes: [
        GoRoute(
          path: '/notes/:id',
          builder: (_, state) =>
              NoteDetailPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swiping moves to the next and previous note (TC-10)', (
    tester,
  ) async {
    await pumpDetail(tester, 'dua');
    expect(find.text('Catatan dua'), findsOneWidget);
    expect(find.text('Catatan 2 dari 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Catatan tiga'), findsOneWidget);
    expect(find.text('Catatan 3 dari 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(500, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(500, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Catatan satu'), findsOneWidget);
  });

  testWidgets('chevron buttons and arrow keys page through notes', (tester) async {
    await pumpDetail(tester, 'satu');
    await tester.tap(find.byTooltip('Catatan berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan dua'), findsOneWidget);

    await tester.tap(find.byTooltip('Catatan sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan satu'), findsOneWidget);

    // Arrow keys still page after a pager button took focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Catatan dua'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Catatan satu'), findsOneWidget);
  });

  testWidgets('editing the shown note keeps it on screen', (tester) async {
    await pumpDetail(tester, 'tiga');
    final tiga = provider.byId('tiga')!;
    // Saving bumps updated_at, which moves tiga to the top of the list.
    await provider.save(
      Note(
        id: tiga.id,
        courseId: tiga.courseId,
        title: 'Catatan tiga (revisi)',
        content: tiga.content,
        noteDate: tiga.noteDate,
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.items.first.id, 'tiga');
    expect(find.text('Catatan tiga (revisi)'), findsOneWidget);
    expect(find.text('Catatan 3 dari 3'), findsOneWidget);
  });
}
