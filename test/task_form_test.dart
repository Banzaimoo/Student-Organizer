import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:student_organizer/core/theme/app_theme.dart';
import 'package:student_organizer/features/courses/data/course.dart';
import 'package:student_organizer/features/courses/data/course_repository.dart';
import 'package:student_organizer/features/courses/providers/course_provider.dart';
import 'package:student_organizer/features/tasks/data/task.dart';
import 'package:student_organizer/features/tasks/data/task_repository.dart';
import 'package:student_organizer/features/tasks/presentation/task_form_page.dart';
import 'package:student_organizer/features/tasks/providers/task_provider.dart';

class _FakeCourses implements CourseRepository {
  final created = <String>[];

  @override
  Future<List<Course>> fetchAll() async => const [];

  @override
  Future<Course> upsertByName(String name) async {
    created.add(name);
    return Course(id: 'course-${created.length}', name: name);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeTasks implements TaskRepository {
  final inserted = <Task>[];

  @override
  Future<Task> insert(Task t) async {
    inserted.add(t);
    return t.copyWith(id: 'task-1');
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  late _FakeCourses courseRepo;
  late _FakeTasks taskRepo;

  Future<void> pumpForm(WidgetTester tester) async {
    courseRepo = _FakeCourses();
    taskRepo = _FakeTasks();
    final courses = CourseProvider(courseRepo);
    final router = GoRouter(
      initialLocation: '/tasks/new',
      routes: [
        GoRoute(
          path: '/tasks',
          builder: (_, _) => const Scaffold(body: Text('Daftar')),
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const TaskFormPage()),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: courses),
          ChangeNotifierProvider(
            create: (_) => TaskProvider(taskRepo, courses),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty form shows required errors and sends nothing (TC-04)', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.tap(find.text('Simpan tugas'));
    await tester.pumpAndSettle();

    expect(find.text('Nama tugas wajib diisi'), findsOneWidget);
    expect(find.text('Mata kuliah wajib diisi'), findsOneWidget);
    expect(find.text('Deadline wajib diisi'), findsOneWidget);
    expect(taskRepo.inserted, isEmpty);
  });

  testWidgets('new course is created on save and linked to the task', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama tugas'),
      'Laporan Praktikum 3',
    );

    await tester.tap(find.text('Mata kuliah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Tambah mata kuliah baru').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama mata kuliah'),
      'Basis Data',
    );
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.text('Basis Data (baru)'), findsOneWidget);
    // Not created until the task is saved.
    expect(courseRepo.created, isEmpty);

    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan tugas'));
    await tester.pumpAndSettle();

    expect(courseRepo.created, ['Basis Data']);
    expect(taskRepo.inserted, hasLength(1));
    final t = taskRepo.inserted.single;
    expect(t.title, 'Laporan Praktikum 3');
    expect(t.courseId, 'course-1');
    expect(t.status, TaskStatus.belum);
    expect(t.deadline.hour, 23);
    expect(t.deadline.minute, 59);
    // Deep-linked form has nothing to pop, so it goes to the list.
    expect(find.text('Daftar'), findsOneWidget);
  });
}
