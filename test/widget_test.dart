import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:student_organizer/core/utils/date_formatter.dart';
import 'package:student_organizer/core/utils/validators.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('Validators', () {
    test('required rejects blank values', () {
      expect(Validators.required('  ', 'Nama tugas'), 'Nama tugas wajib diisi');
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('x'), isNull);
    });

    test('password needs at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('email format', () {
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b.co'), isNull);
    });

    test('endAfterStart rejects end <= start (TC-07)', () {
      const nine = TimeOfDay(hour: 9, minute: 0);
      const ten = TimeOfDay(hour: 10, minute: 0);
      expect(Validators.endAfterStart(ten, nine),
          'Jam selesai harus setelah jam mulai');
      expect(Validators.endAfterStart(nine, nine), isNotNull);
      expect(Validators.endAfterStart(nine, ten), isNull);
    });
  });

  group('DateFormatter', () {
    test('formats date in Indonesian', () {
      expect(DateFormatter.date(DateTime(2026, 10, 26)), 'Senin, 26 Okt 2026');
    });

    test('formats time as 08.00', () {
      expect(DateFormatter.time(const TimeOfDay(hour: 8, minute: 0)), '08.00');
    });

    test('round-trips Postgres time', () {
      final t = DateFormatter.parseTime('08:30:00');
      expect(DateFormatter.toDbTime(t), '08:30:00');
    });

    test('day names', () {
      expect(DateFormatter.dayName(1), 'Senin');
      expect(DateFormatter.dayName(7), 'Minggu');
    });
  });
}
