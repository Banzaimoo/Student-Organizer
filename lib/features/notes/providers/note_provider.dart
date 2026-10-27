import 'package:flutter/foundation.dart';

import '../../../core/utils/error_messages.dart';
import '../../courses/providers/course_provider.dart';
import '../data/note.dart';
import '../data/note_repository.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider(this._repo, this._courses);

  final NoteRepository _repo;
  final CourseProvider _courses;

  List<Note> items = [];
  bool loading = false;
  bool saving = false;
  bool _loaded = false;

  /// Error from the last list load; form/delete errors are returned instead.
  String? error;

  /// Grid or list layout of the list page (FR-NOTE-01).
  bool gridView = true;

  /// Search text and selected course id; empty/null show all (FR-NOTE-04).
  String query = '';
  String? courseFilter;

  bool get hasLoaded => _loaded;

  bool get isFiltering => query.trim().isNotEmpty || courseFilter != null;

  List<Note> get visible => [
    for (final n in items)
      if ((courseFilter == null || n.courseId == courseFilter) &&
          n.matches(query))
        n,
  ];

  /// Courses that have at least one note, as id → name, sorted by name.
  Map<String, String> get courses {
    final found = <String, String>{
      for (final n in items)
        if (n.courseId != null) n.courseId!: n.courseName ?? 'Mata kuliah',
    };
    final entries = found.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return Map.fromEntries(entries);
  }

  Note? byId(String id) {
    for (final n in items) {
      if (n.id == id) return n;
    }
    return null;
  }

  void toggleView() {
    gridView = !gridView;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCourseFilter(String? courseId) {
    courseFilter = courseId;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = (await _repo.fetchAll())..sort(Note.compare);
      _loaded = true;
      // Drop a filter whose course no longer has notes.
      if (courseFilter != null && !courses.containsKey(courseFilter)) {
        courseFilter = null;
      }
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Note?> fetch(String id) async {
    final cached = byId(id);
    if (cached != null) return cached;
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  /// Saves [n] (insert when it has no id). A note with a [Note.courseName]
  /// but no [Note.courseId] names a new course, created here so a cancelled
  /// form leaves no stray course behind (FR-CRS-03). Returns an error
  /// message, or null on success.
  Future<String?> save(Note n) async {
    saving = true;
    notifyListeners();
    try {
      var toSave = n;
      if (n.courseId == null && n.courseName != null) {
        final course = await _courses.ensure(n.courseName!);
        toSave = n.copyWith(courseId: course.id);
      }
      final saved = n.id == null
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

  Future<String?> delete(String id) async {
    try {
      await _repo.delete(id);
      items = items.where((n) => n.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Puts [saved] in place of its old copy; the fresh `updated_at` moves it
  /// to the top (FR-NOTE-03).
  void _replace(Note saved) {
    items = [
      for (final o in items)
        if (o.id != saved.id) o,
      saved,
    ]..sort(Note.compare);
  }

  /// Drops cached data, e.g. after logout so the next user sees nothing stale.
  void clear() {
    items = [];
    _loaded = false;
    query = '';
    courseFilter = null;
    error = null;
    notifyListeners();
  }
}
