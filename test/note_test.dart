import 'package:flutter_test/flutter_test.dart';
import 'package:student_organizer/features/notes/data/note.dart';

Note _n(String id, DateTime? updatedAt) => Note(
  id: id,
  title: id,
  content: 'Isi $id',
  noteDate: DateTime(2026, 10, 27),
  updatedAt: updatedAt,
);

void main() {
  group('Note', () {
    test('fromJson / toJson round-trip', () {
      final n = Note.fromJson({
        'id': 'n1',
        'course_id': 'c1',
        'courses': {'name': 'Basis Data'},
        'title': 'Normalisasi',
        'content': '1NF, 2NF, 3NF',
        'note_date': '2026-10-27',
        'created_at': '2026-10-27T01:00:00+00:00',
        'updated_at': '2026-10-27T02:30:00+00:00',
      });
      expect(n.courseName, 'Basis Data');
      expect(n.noteDate, DateTime(2026, 10, 27));
      expect(n.updatedAt, DateTime.utc(2026, 10, 27, 2, 30).toLocal());
      expect(n.toJson(), {
        'course_id': 'c1',
        'title': 'Normalisasi',
        'content': '1NF, 2NF, 3NF',
        'note_date': '2026-10-27',
      });
    });

    test('note_date keeps the local calendar day', () {
      // Local midnight is the previous day in UTC east of Greenwich.
      final n = Note(title: 'a', content: 'b', noteDate: DateTime(2026, 1, 5));
      expect(n.toJson()['note_date'], '2026-01-05');
    });

    test('toJson trims title and content', () {
      final n = Note(
        title: '  Judul ',
        content: '\n isi \n',
        noteDate: DateTime(2026, 10, 27),
      );
      expect(n.toJson()['title'], 'Judul');
      expect(n.toJson()['content'], 'isi');
    });

    test('compare puts the most recently updated first', () {
      final notes = [
        _n('old', DateTime(2026, 10, 1)),
        _n('new', DateTime(2026, 10, 20)),
        _n('mid', DateTime(2026, 10, 10)),
      ]..sort(Note.compare);
      expect(notes.map((n) => n.id), ['new', 'mid', 'old']);
    });

    test('matches title or content, ignoring case', () {
      final n = _n('Basis', null);
      expect(n.matches('basis'), isTrue);
      expect(n.matches('ISI'), isTrue);
      expect(n.matches('  '), isTrue);
      expect(n.matches('jaringan'), isFalse);
    });
  });
}
