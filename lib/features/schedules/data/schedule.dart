import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';

class Schedule {
  const Schedule({
    this.id,
    this.courseId,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.lecturer,
  });

  /// Null for a schedule that has not been saved yet.
  final String? id;
  final String? courseId;
  final String courseName;

  /// 1 = Senin … 7 = Minggu.
  final int dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;
  final String lecturer;

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        id: json['id'] as String,
        courseId: json['course_id'] as String?,
        courseName: json['course_name'] as String,
        dayOfWeek: json['day_of_week'] as int,
        startTime: DateFormatter.parseTime(json['start_time'] as String),
        endTime: DateFormatter.parseTime(json['end_time'] as String),
        room: json['room'] as String,
        lecturer: json['lecturer'] as String,
      );

  /// Columns written on insert/update. `user_id` comes from the DB default.
  Map<String, dynamic> toJson() => {
        'course_id': courseId,
        'course_name': courseName.trim(),
        'day_of_week': dayOfWeek,
        'start_time': DateFormatter.toDbTime(startTime),
        'end_time': DateFormatter.toDbTime(endTime),
        'room': room.trim(),
        'lecturer': lecturer.trim(),
      };

  Schedule copyWith({String? id, String? courseId}) => Schedule(
        id: id ?? this.id,
        courseId: courseId ?? this.courseId,
        courseName: courseName,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
        lecturer: lecturer,
      );

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  int get startMinutes => _minutes(startTime);
  int get endMinutes => _minutes(endTime);

  /// True when both are on the same day and their time ranges intersect.
  /// Back-to-back classes (one ends when the next starts) do not clash.
  bool overlaps(Schedule other) =>
      dayOfWeek == other.dayOfWeek &&
      startMinutes < other.endMinutes &&
      other.startMinutes < endMinutes;

  /// Senin→Minggu, then by start time (FR-SCH-02).
  static int compare(Schedule a, Schedule b) {
    final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
    return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
  }

  /// `08.00–09.40`
  String get timeRange =>
      '${DateFormatter.time(startTime)}–${DateFormatter.time(endTime)}';
}
