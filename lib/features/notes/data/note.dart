import '../../../core/utils/date_formatter.dart';

class Note {
  const Note({
    this.id,
    this.courseId,
    this.courseName,
    required this.title,
    required this.content,
    required this.noteDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Null for a note that has not been saved yet.
  final String? id;

  /// Null when the course was deleted (`on delete set null`).
  final String? courseId;

  /// From the `courses(name)` join; null together with [courseId].
  final String? courseName;
  final String title;
  final String content;

  /// Calendar day only (Postgres `date`), as local midnight.
  final DateTime noteDate;

  /// Set by the database; null before the first save.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Note.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>?;
    DateTime? stamp(String key) {
      final v = json[key] as String?;
      return v == null ? null : DateTime.parse(v).toLocal();
    }

    return Note(
      id: json['id'] as String,
      courseId: json['course_id'] as String?,
      courseName: course?['name'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      // A bare `yyyy-MM-dd` parses as local midnight, so the day is kept.
      noteDate: DateTime.parse(json['note_date'] as String),
      createdAt: stamp('created_at'),
      updatedAt: stamp('updated_at'),
    );
  }

  /// Columns written on insert/update. `user_id` comes from the DB default
  /// and `updated_at` from the trigger (FR-NOTE-08).
  Map<String, dynamic> toJson() => {
    'course_id': courseId,
    'title': title.trim(),
    'content': content.trim(),
    'note_date': DateFormatter.toDbDate(noteDate),
  };

  Note copyWith({String? id, String? courseId, DateTime? updatedAt}) => Note(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    courseName: courseName,
    title: title,
    content: content,
    noteDate: noteDate,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Last edited first (FR-NOTE-03); unsaved notes count as newest.
  static int compare(Note a, Note b) {
    final au = a.updatedAt, bu = b.updatedAt;
    if (au == null || bu == null) return au == bu ? 0 : (au == null ? -1 : 1);
    return bu.compareTo(au);
  }

  /// Case-insensitive match on title or content (FR-NOTE-04).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        title.toLowerCase().contains(q) ||
        content.toLowerCase().contains(q);
  }
}
