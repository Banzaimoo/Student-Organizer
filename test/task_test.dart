import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:student_organizer/core/utils/date_formatter.dart';
import 'package:student_organizer/features/tasks/data/task.dart';
import 'package:student_organizer/features/tasks/presentation/widgets/task_card.dart';

Task _t(
  String title,
  DateTime deadline, [
  TaskStatus status = TaskStatus.belum,
]) => Task(id: title, title: title, deadline: deadline, status: status);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('Task', () {
    test('fromJson reads the joined course and converts deadline to local', () {
      final t = Task.fromJson({
        'id': 't1',
        'course_id': 'c1',
        'courses': {'name': 'Basis Data'},
        'title': 'Laporan Praktikum 3',
        'description': null,
        'deadline': '2026-10-27T16:59:00+00:00',
        'status': 'sedang',
      });
      expect(t.courseName, 'Basis Data');
      expect(t.status, TaskStatus.sedang);
      expect(t.deadline.isUtc, isFalse);
      expect(
        t.deadline.isAtSameMomentAs(DateTime.utc(2026, 10, 27, 16, 59)),
        isTrue,
      );
    });

    test('fromJson tolerates a deleted course', () {
      final t = Task.fromJson({
        'id': 't1',
        'course_id': null,
        'courses': null,
        'title': 'Kuis',
        'deadline': '2026-10-27T01:00:00Z',
        'status': 'belum',
      });
      expect(t.courseId, isNull);
      expect(t.courseName, isNull);
    });

    test('toJson writes UTC, trims text and drops an empty description', () {
      final local = DateTime(2026, 10, 27, 23, 59);
      final json = Task(
        courseId: 'c1',
        courseName: 'Basis Data',
        title: '  Laporan ',
        description: '   ',
        deadline: local,
        status: TaskStatus.selesai,
      ).toJson();
      expect(json, {
        'course_id': 'c1',
        'title': 'Laporan',
        'description': null,
        'deadline': local.toUtc().toIso8601String(),
        'status': 'selesai',
      });
      expect(DateTime.parse(json['deadline'] as String).toLocal(), local);
    });

    test('isOverdue only for unfinished tasks past the deadline', () {
      final now = DateTime(2026, 10, 27, 12);
      final past = DateTime(2026, 10, 27, 11, 59);
      expect(_t('a', past).isOverdue(now), isTrue);
      expect(_t('b', past, TaskStatus.sedang).isOverdue(now), isTrue);
      expect(_t('c', past, TaskStatus.selesai).isOverdue(now), isFalse);
      expect(_t('d', DateTime(2026, 10, 27, 12, 1)).isOverdue(now), isFalse);
    });

    test('compare puts nearest deadline first and finished tasks last', () {
      final list = [
        _t('done-early', DateTime(2026, 10, 1), TaskStatus.selesai),
        _t('later', DateTime(2026, 11, 5)),
        _t('sooner', DateTime(2026, 10, 28), TaskStatus.sedang),
        _t('done-late', DateTime(2026, 12, 1), TaskStatus.selesai),
      ]..sort(Task.compare);
      expect(list.map((t) => t.title), [
        'sooner',
        'later',
        'done-early',
        'done-late',
      ]);
    });

    test('status maps to the Postgres enum values', () {
      expect(TaskStatus.values.map((s) => s.name), [
        'belum',
        'sedang',
        'selesai',
      ]);
      expect(TaskStatus.fromDb('selesai'), TaskStatus.selesai);
    });
  });

  group('deadline labels', () {
    final now = DateTime(2026, 10, 27, 9);

    test('relative day names', () {
      expect(
        DateFormatter.relativeDay(DateTime(2026, 10, 27, 23), now),
        'Hari ini',
      );
      expect(DateFormatter.relativeDay(DateTime(2026, 10, 28), now), 'Besok');
      expect(DateFormatter.relativeDay(DateTime(2026, 10, 26), now), 'Kemarin');
      expect(
        DateFormatter.relativeDay(DateTime(2026, 11, 2), now),
        'Sen, 2 Nov',
      );
      expect(
        DateFormatter.relativeDay(DateTime(2027, 1, 4), now),
        'Sen, 4 Jan 2027',
      );
    });

    test('deadlineLabel adds the time', () {
      expect(
        deadlineLabel(DateTime(2026, 10, 28, 23, 59), now),
        'Besok · 23.59',
      );
    });
  });
}
