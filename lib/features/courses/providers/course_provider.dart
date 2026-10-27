import 'package:flutter/foundation.dart';

import '../data/course.dart';
import '../data/course_repository.dart';

/// Course list for the dropdowns in Jadwal, Tugas and Catatan.
class CourseProvider extends ChangeNotifier {
  CourseProvider(this._repo);

  final CourseRepository _repo;

  List<Course> courses = [];

  /// Loads courses; failures are silent because the list is only a helper
  /// for autocomplete and the user can still type a name.
  Future<void> load() async {
    try {
      courses = await _repo.fetchAll();
      notifyListeners();
    } catch (_) {}
  }

  /// Returns the course named [name], creating it when it does not exist.
  Future<Course> ensure(String name) async {
    final trimmed = name.trim();
    for (final c in courses) {
      if (c.name.toLowerCase() == trimmed.toLowerCase()) return c;
    }
    final course = await _repo.upsertByName(trimmed);
    courses = [...courses, course]..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return course;
  }

  void clear() {
    courses = [];
    notifyListeners();
  }
}
