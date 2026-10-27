import 'package:flutter/foundation.dart';

import '../../../core/utils/error_messages.dart';
import '../../courses/providers/course_provider.dart';
import '../data/schedule.dart';
import '../data/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider(this._repo, this._courses);

  final ScheduleRepository _repo;
  final CourseProvider _courses;

  List<Schedule> items = [];
  bool loading = false;
  bool saving = false;
  bool _loaded = false;

  /// Error from the last list load; form/delete errors are returned instead.
  String? error;

  /// Selected day filter; null means "Semua" (FR-SCH-03).
  int? dayFilter;

  bool get hasLoaded => _loaded;

  List<Schedule> get visible => dayFilter == null
      ? items
      : items.where((s) => s.dayOfWeek == dayFilter).toList();

  /// Visible items grouped by day, in Senin→Minggu order.
  Map<int, List<Schedule>> get grouped {
    final map = <int, List<Schedule>>{};
    for (final s in visible) {
      (map[s.dayOfWeek] ??= []).add(s);
    }
    return map;
  }

  Schedule? byId(String id) {
    for (final s in items) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Other schedules that overlap [s] (FR-SCH-09). Warns only, never blocks.
  List<Schedule> clashesWith(Schedule s) =>
      items.where((o) => o.id != s.id && o.overlaps(s)).toList();

  void setDayFilter(int? day) {
    dayFilter = day;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.fetchAll();
      _loaded = true;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Schedule?> fetch(String id) async {
    final cached = byId(id);
    if (cached != null) return cached;
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  /// Saves [s] (insert when it has no id). Returns an error message, or null
  /// on success.
  Future<String?> save(Schedule s) async {
    saving = true;
    notifyListeners();
    try {
      // Keep `courses` in sync so Tugas/Catatan can pick this course (FR-CRS-01).
      final course = await _courses.ensure(s.courseName);
      final withCourse = s.copyWith(courseId: course.id);
      final saved = s.id == null
          ? await _repo.insert(withCourse)
          : await _repo.update(withCourse);
      items = [
        for (final o in items)
          if (o.id != saved.id) o,
        saved,
      ]..sort(Schedule.compare);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repo.delete(id);
      items = items.where((s) => s.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Drops cached data, e.g. after logout so the next user sees nothing stale.
  void clear() {
    items = [];
    _loaded = false;
    dayFilter = null;
    error = null;
    notifyListeners();
  }
}
