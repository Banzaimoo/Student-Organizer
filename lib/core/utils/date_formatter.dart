import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static const _locale = 'id_ID';

  /// `Senin, 26 Okt 2026`
  static String date(DateTime d) =>
      DateFormat('EEEE, d MMM yyyy', _locale).format(d);

  /// `Sen, 26 Okt`, with the year added when it is not [now]'s year.
  static String shortDate(DateTime d, [DateTime? now]) {
    final sameYear = d.year == (now ?? DateTime.now()).year;
    return DateFormat(sameYear ? 'EEE, d MMM' : 'EEE, d MMM yyyy', _locale)
        .format(d);
  }

  /// `Hari ini`, `Besok`, `Kemarin`, otherwise [shortDate].
  static String relativeDay(DateTime d, [DateTime? now]) {
    now ??= DateTime.now();
    // Rounded so a DST shift (23 h or 25 h day) still counts as one day.
    final hours =
        DateUtils.dateOnly(d).difference(DateUtils.dateOnly(now)).inHours;
    return switch ((hours / 24).round()) {
      0 => 'Hari ini',
      1 => 'Besok',
      -1 => 'Kemarin',
      _ => shortDate(d, now),
    };
  }

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

  /// Formats for Postgres `date` columns: `2026-10-26`. Uses the local
  /// calendar day; converting to UTC first could move it a day back.
  static String toDbDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static const dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// 1 = Senin … 7 = Minggu.
  static String dayName(int dayOfWeek) => dayNames[dayOfWeek - 1];
}
