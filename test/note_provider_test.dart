import 'package:flutter_test/flutter_test.dart';
import 'package:student_organizer/features/courses/data/course_repository.dart';
import 'package:student_organizer/features/courses/providers/course_provider.dart';
import 'package:student_organizer/features/notes/data/note.dart';
import 'package:student_organizer/features/notes/data/note_repository.dart';
import 'package:student_organizer/features/notes/providers/note_provider.dart';

class _FakeCourses implements CourseRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// In-memory stand-in for the `notes` table; update bumps `updated_at`
/// like the trigger does.
class _FakeNotes implements NoteRepository {
  _FakeNotes(this.rows);

  final List<Note> rows;

  @override
  Future<List<Note>> fetchAll() async => [...rows];

  @override
  Future<Note> update(Note n) async =>
      n.copyWith(updatedAt: DateTime(2026, 12));

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Note _n(String id, int day, {String? courseId, String? courseName}) => Note(
  id: id,
  courseId: courseId,
  courseName: courseName,
  title: 'Judul $id',
  content: 'Isi $id',
  noteDate: DateTime(2026, 11, day),
  updatedAt: DateTime(2026, 11, day),
);

void main() {
  late NoteProvider provider;

  setUp(() async {
    provider = NoteProvider(
      _FakeNotes([
        _n('a', 1, courseId: 'bd', courseName: 'Basis Data'),
        _n('c', 3, courseId: 'jk', courseName: 'Jaringan Komputer'),
        _n('b', 2, courseId: 'bd', courseName: 'Basis Data'),
      ]),
      CourseProvider(_FakeCourses()),
    );
    await provider.load();
  });

  test('load puts the last updated note first', () {
    expect(provider.items.map((n) => n.id), ['c', 'b', 'a']);
  });

  test('editing a note moves it to the top (TC-11)', () async {
    final a = provider.byId('a')!;
    final error = await provider.save(
      Note(
        id: a.id,
        courseId: a.courseId,
        title: a.title,
        content: 'Isi baru',
        noteDate: a.noteDate,
      ),
    );
    expect(error, isNull);
    expect(provider.items.map((n) => n.id), ['a', 'c', 'b']);
    expect(provider.byId('a')!.content, 'Isi baru');
    expect(provider.byId('a')!.updatedAt, DateTime(2026, 12));
  });

  test('search and course filter', () {
    provider.setQuery('judul B');
    expect(provider.visible.map((n) => n.id), ['b']);

    provider.setQuery('');
    provider.setCourseFilter('bd');
    expect(provider.visible.map((n) => n.id), ['b', 'a']);
    expect(provider.isFiltering, isTrue);
  });

  test('courses lists each course with notes once, by name', () {
    expect(provider.courses, {'bd': 'Basis Data', 'jk': 'Jaringan Komputer'});
  });

  test('clear forgets notes and filters', () {
    provider
      ..setQuery('x')
      ..setCourseFilter('bd')
      ..clear();
    expect(provider.items, isEmpty);
    expect(provider.hasLoaded, isFalse);
    expect(provider.isFiltering, isFalse);
  });
}
