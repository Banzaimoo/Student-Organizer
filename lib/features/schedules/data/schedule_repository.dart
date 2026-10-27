import 'package:supabase_flutter/supabase_flutter.dart';

import 'schedule.dart';

class ScheduleRepository {
  final _db = Supabase.instance.client;

  Future<List<Schedule>> fetchAll() async {
    final rows = await _db
        .from('schedules')
        .select()
        // postgrest-dart orders descending unless told otherwise.
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);
    return rows.map(Schedule.fromJson).toList();
  }

  Future<Schedule> fetchById(String id) async {
    final row = await _db.from('schedules').select().eq('id', id).single();
    return Schedule.fromJson(row);
  }

  Future<Schedule> insert(Schedule s) async {
    final row =
        await _db.from('schedules').insert(s.toJson()).select().single();
    return Schedule.fromJson(row);
  }

  Future<Schedule> update(Schedule s) async {
    final row = await _db
        .from('schedules')
        .update(s.toJson())
        .eq('id', s.id!)
        .select()
        .single();
    return Schedule.fromJson(row);
  }

  Future<void> delete(String id) => _db.from('schedules').delete().eq('id', id);
}
