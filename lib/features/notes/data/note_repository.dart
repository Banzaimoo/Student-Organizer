import 'package:supabase_flutter/supabase_flutter.dart';

import 'note.dart';

class NoteRepository {
  final _db = Supabase.instance.client;

  /// Joins the course name so cards need no second query.
  static const _columns = '*, courses(name)';

  Future<List<Note>> fetchAll() async {
    final rows = await _db
        .from('notes')
        .select(_columns)
        .order('updated_at', ascending: false);
    return rows.map(Note.fromJson).toList();
  }

  Future<Note> fetchById(String id) async {
    final row = await _db.from('notes').select(_columns).eq('id', id).single();
    return Note.fromJson(row);
  }

  /// Returns the stored row, so the caller gets the DB timestamps.
  Future<Note> insert(Note n) async {
    final row = await _db
        .from('notes')
        .insert(n.toJson())
        .select(_columns)
        .single();
    return Note.fromJson(row);
  }

  /// Returns the stored row with the `updated_at` set by the trigger.
  Future<Note> update(Note n) async {
    final row = await _db
        .from('notes')
        .update(n.toJson())
        .eq('id', n.id!)
        .select(_columns)
        .single();
    return Note.fromJson(row);
  }

  Future<void> delete(String id) => _db.from('notes').delete().eq('id', id);
}
