import 'package:flutter_test/flutter_test.dart';
import 'package:student_organizer/features/courses/data/course_repository.dart';
import 'package:student_organizer/features/courses/providers/course_provider.dart';
import 'package:student_organizer/features/tasks/data/task.dart';
import 'package:student_organizer/features/tasks/data/task_repository.dart';
import 'package:student_organizer/features/tasks/providers/task_provider.dart';

class _FakeCourses implements CourseRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// In-memory stand-in for the `tasks` table.
class _FakeTasks implements TaskRepository {
  _FakeTasks(this.rows);

  final List<Task> rows;

  @override
  Future<List<Task>> fetchAll() async => [...rows];

  @override
  Future<Task> updateStatus(String id, TaskStatus status) async =>
      rows.firstWhere((t) => t.id == id).copyWith(status: status);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Task _t(String id, int day, [TaskStatus status = TaskStatus.belum]) =>
    Task(id: id, title: id, deadline: DateTime(2026, 11, day), status: status);

void main() {
  late TaskProvider provider;

  setUp(() async {
    provider = TaskProvider(
      _FakeTasks([_t('c', 3), _t('a', 1), _t('b', 2, TaskStatus.sedang)]),
      CourseProvider(_FakeCourses()),
    );
    await provider.load();
  });

  test('load sorts by nearest deadline', () {
    expect(provider.items.map((t) => t.id), ['a', 'b', 'c']);
  });

  test('marking a task Selesai moves it to the bottom (TC-06)', () async {
    final error = await provider.setStatus(
      provider.byId('a')!,
      TaskStatus.selesai,
    );
    expect(error, isNull);
    expect(provider.items.map((t) => t.id), ['b', 'c', 'a']);
    expect(provider.byId('a')!.status, TaskStatus.selesai);
  });

  test('status filter and counts', () {
    provider.setStatusFilter(TaskStatus.sedang);
    expect(provider.visible.map((t) => t.id), ['b']);
    expect(provider.count(null), 3);
    expect(provider.count(TaskStatus.belum), 2);
  });
}
