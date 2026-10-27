import 'package:flutter/foundation.dart';

import '../../../core/utils/error_messages.dart';
import '../../courses/providers/course_provider.dart';
import '../data/task.dart';
import '../data/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._repo, this._courses);

  final TaskRepository _repo;
  final CourseProvider _courses;

  List<Task> items = [];
  bool loading = false;
  bool saving = false;
  bool _loaded = false;

  /// Error from the last list load; form/delete errors are returned instead.
  String? error;

  /// Selected status filter; null means "Semua" (FR-TASK-04).
  TaskStatus? statusFilter;

  bool get hasLoaded => _loaded;

  List<Task> get visible => statusFilter == null
      ? items
      : items.where((t) => t.status == statusFilter).toList();

  /// Number of tasks with [status], or all tasks when null.
  int count(TaskStatus? status) => status == null
      ? items.length
      : items.where((t) => t.status == status).length;

  Task? byId(String id) {
    for (final t in items) {
      if (t.id == id) return t;
    }
    return null;
  }

  void setStatusFilter(TaskStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = (await _repo.fetchAll())..sort(Task.compare);
      _loaded = true;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Task?> fetch(String id) async {
    final cached = byId(id);
    if (cached != null) return cached;
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  /// Saves [t] (insert when it has no id). A task with a [Task.courseName]
  /// but no [Task.courseId] names a new course, created here so a cancelled
  /// form leaves no stray course behind (FR-CRS-03). Returns an error
  /// message, or null on success.
  Future<String?> save(Task t) async {
    saving = true;
    notifyListeners();
    try {
      var toSave = t;
      if (t.courseId == null && t.courseName != null) {
        final course = await _courses.ensure(t.courseName!);
        toSave = t.copyWith(courseId: course.id);
      }
      final saved = t.id == null
          ? await _repo.insert(toSave)
          : await _repo.update(toSave);
      _replace(saved);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  /// Quick status change from a card or the detail page.
  Future<String?> setStatus(Task t, TaskStatus status) async {
    if (t.status == status) return null;
    try {
      _replace(await _repo.updateStatus(t.id!, status));
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repo.delete(id);
      items = items.where((t) => t.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Puts [saved] in place of its old copy, keeping the list order
  /// (finished tasks move to the bottom, FR-TASK-02).
  void _replace(Task saved) {
    items = [
      for (final o in items)
        if (o.id != saved.id) o,
      saved,
    ]..sort(Task.compare);
  }

  /// Drops cached data, e.g. after logout so the next user sees nothing stale.
  void clear() {
    items = [];
    _loaded = false;
    statusFilter = null;
    error = null;
    notifyListeners();
  }
}
