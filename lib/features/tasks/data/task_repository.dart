import 'package:supabase_flutter/supabase_flutter.dart';

import 'task.dart';

class TaskRepository {
  final _db = Supabase.instance.client;

  /// Joins the course name so cards need no second query.
  static const _columns = '*, courses(name)';

  Future<List<Task>> fetchAll() async {
    final rows = await _db
        .from('tasks')
        .select(_columns)
        // postgrest-dart orders descending unless told otherwise.
        .order('deadline', ascending: true);
    return rows.map(Task.fromJson).toList();
  }

  Future<Task> fetchById(String id) async {
    final row = await _db.from('tasks').select(_columns).eq('id', id).single();
    return Task.fromJson(row);
  }

  Future<Task> insert(Task t) async {
    final row = await _db
        .from('tasks')
        .insert(t.toJson())
        .select(_columns)
        .single();
    return Task.fromJson(row);
  }

  Future<Task> update(Task t) async {
    final row = await _db
        .from('tasks')
        .update(t.toJson())
        .eq('id', t.id!)
        .select(_columns)
        .single();
    return Task.fromJson(row);
  }

  Future<Task> updateStatus(String id, TaskStatus status) async {
    final row = await _db
        .from('tasks')
        .update({'status': status.name})
        .eq('id', id)
        .select(_columns)
        .single();
    return Task.fromJson(row);
  }

  Future<void> delete(String id) => _db.from('tasks').delete().eq('id', id);
}
