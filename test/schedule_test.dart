import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_organizer/features/schedules/data/schedule.dart';

Schedule _s(int day, int sh, int sm, int eh, int em, [String name = 'Basis Data']) =>
    Schedule(
      id: '$name-$day-$sh$sm',
      courseName: name,
      dayOfWeek: day,
      startTime: TimeOfDay(hour: sh, minute: sm),
      endTime: TimeOfDay(hour: eh, minute: em),
      room: 'Gedung F 2.3',
      lecturer: 'Dr. Siti Rahma',
    );

void main() {
  group('Schedule', () {
    test('fromJson / toJson round-trip', () {
      final s = Schedule.fromJson({
        'id': 'a1',
        'course_id': 'c1',
        'course_name': 'Basis Data',
        'day_of_week': 1,
        'start_time': '08:00:00',
        'end_time': '09:40:00',
        'room': 'Gedung F 2.3',
        'lecturer': 'Dr. Siti Rahma',
      });
      expect(s.timeRange, '08.00–09.40');
      expect(s.toJson(), {
        'course_id': 'c1',
        'course_name': 'Basis Data',
        'day_of_week': 1,
        'start_time': '08:00:00',
        'end_time': '09:40:00',
        'room': 'Gedung F 2.3',
        'lecturer': 'Dr. Siti Rahma',
      });
    });

    test('toJson trims text fields', () {
      final s = Schedule(
        courseName: '  Basis Data ',
        dayOfWeek: 2,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 0),
        room: ' F2 ',
        lecturer: ' Budi ',
      );
      final json = s.toJson();
      expect(json['course_name'], 'Basis Data');
      expect(json['room'], 'F2');
      expect(json['lecturer'], 'Budi');
    });

    test('overlaps only on the same day with intersecting times', () {
      final a = _s(1, 8, 0, 9, 40);
      expect(a.overlaps(_s(1, 9, 0, 10, 0)), isTrue);
      expect(a.overlaps(_s(1, 7, 0, 12, 0)), isTrue);
      // Back-to-back classes do not clash.
      expect(a.overlaps(_s(1, 9, 40, 11, 20)), isFalse);
      expect(a.overlaps(_s(2, 8, 0, 9, 40)), isFalse);
    });

    test('compare sorts Senin to Minggu, then by start time', () {
      final list = [
        _s(7, 8, 0, 9, 0, 'D'),
        _s(1, 10, 0, 11, 0, 'B'),
        _s(3, 7, 0, 8, 0, 'C'),
        _s(1, 7, 30, 9, 0, 'A'),
      ]..sort(Schedule.compare);
      expect(list.map((s) => s.courseName), ['A', 'B', 'C', 'D']);
    });
  });
}
