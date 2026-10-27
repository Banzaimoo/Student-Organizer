import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:student_organizer/core/theme/app_theme.dart';
import 'package:student_organizer/features/courses/data/course.dart';
import 'package:student_organizer/features/courses/data/course_repository.dart';
import 'package:student_organizer/features/courses/providers/course_provider.dart';
import 'package:student_organizer/features/notes/data/note.dart';
import 'package:student_organizer/features/notes/data/note_repository.dart';
import 'package:student_organizer/features/notes/presentation/note_form_page.dart';
import 'package:student_organizer/features/notes/providers/note_provider.dart';

class _FakeCourses implements CourseRepository {
  @override
  Future<List<Course>> fetchAll() async => const [
    Course(id: 'bd', name: 'Basis Data'),
  ];

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeNotes implements NoteRepository {
  final inserted = <Note>[];

  @override
  Future<Note> insert(Note n) async {
    inserted.add(n);
    return n.copyWith(id: 'note-1', updatedAt: DateTime.now());
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  late _FakeNotes noteRepo;

  Future<void> pumpForm(WidgetTester tester) async {
    noteRepo = _FakeNotes();
    final courses = CourseProvider(_FakeCourses());
    final router = GoRouter(
      initialLocation: '/notes/new',
      routes: [
        GoRoute(
          path: '/notes',
          builder: (_, _) => const Scaffold(body: Text('Daftar')),
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const NoteFormPage()),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: courses),
          ChangeNotifierProvider(
            create: (_) => NoteProvider(noteRepo, courses),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty form shows required errors and sends nothing', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.ensureVisible(find.text('Simpan catatan'));
    await tester.tap(find.text('Simpan catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Mata kuliah wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
    // The date defaults to today, so it is never empty.
    expect(find.text('Tanggal wajib diisi'), findsNothing);
    expect(noteRepo.inserted, isEmpty);
  });

  testWidgets('valid note is saved with today as its date', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul'),
      'Normalisasi',
    );
    await tester.tap(find.text('Mata kuliah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basis Data').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Isi catatan'),
      '1NF: atribut atomik\n2NF: tanpa dependensi parsial',
    );

    await tester.ensureVisible(find.text('Simpan catatan'));
    await tester.tap(find.text('Simpan catatan'));
    await tester.pumpAndSettle();

    final n = noteRepo.inserted.single;
    expect(n.title, 'Normalisasi');
    expect(n.courseId, 'bd');
    expect(n.content, contains('2NF'));
    expect(n.noteDate, DateUtils.dateOnly(DateTime.now()));
    // Deep-linked form has nothing to pop, so it goes to the list.
    expect(find.text('Daftar'), findsOneWidget);
  });
}
