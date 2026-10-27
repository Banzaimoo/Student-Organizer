import 'package:supabase_flutter/supabase_flutter.dart';

import 'course.dart';

class CourseRepository {
  final _db = Supabase.instance.client;

  Future<List<Course>> fetchAll() async {
    final rows = await _db
        .from('courses')
        .select('id, name')
        .order('name', ascending: true);
    return rows.map(Course.fromJson).toList();
  }

  /// Returns the user's course named [name], creating it if needed (FR-CRS-01).
  Future<Course> upsertByName(String name) async {
    final row = await _db
        .from('courses')
        .upsert({'name': name.trim()}, onConflict: 'user_id,name')
        .select('id, name')
        .single();
    return Course.fromJson(row);
  }
}
