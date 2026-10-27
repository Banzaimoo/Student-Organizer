import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static const _locale = 'id_ID';

  /// `Senin, 26 Okt 2026`
  static String date(DateTime d) =>
      DateFormat('EEEE, d MMM yyyy', _locale).format(d);

  /// `08.00`
  static String time(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  /// Parses a Postgres `time` string such as `08:00:00`.
  static TimeOfDay parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  /// Formats for Postgres `time` columns: `08:00:00`.
  static String toDbTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  static const dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// 1 = Senin … 7 = Minggu.
  static String dayName(int dayOfWeek) => dayNames[dayOfWeek - 1];
}
