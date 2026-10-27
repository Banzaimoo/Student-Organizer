/// Mirrors the `task_status` enum in Postgres.
enum TaskStatus {
  belum('Belum'),
  sedang('Sedang'),
  selesai('Selesai');

  const TaskStatus(this.label);

  final String label;

  static TaskStatus fromDb(String value) =>
      values.firstWhere((s) => s.name == value, orElse: () => belum);
}

class Task {
  const Task({
    this.id,
    this.courseId,
    this.courseName,
    required this.title,
    this.description,
    required this.deadline,
    this.status = TaskStatus.belum,
  });

  /// Null for a task that has not been saved yet.
  final String? id;

  /// Null when the course was deleted (`on delete set null`).
  final String? courseId;

  /// From the `courses(name)` join; null together with [courseId].
  final String? courseName;
  final String title;
  final String? description;

  /// Local time. Stored as `timestamptz`.
  final DateTime deadline;
  final TaskStatus status;

  factory Task.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>?;
    return Task(
      id: json['id'] as String,
      courseId: json['course_id'] as String?,
      courseName: course?['name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: DateTime.parse(json['deadline'] as String).toLocal(),
      status: TaskStatus.fromDb(json['status'] as String),
    );
  }

  /// Columns written on insert/update. `user_id` comes from the DB default.
  /// The deadline goes out in UTC so Postgres does not read local time as UTC.
  Map<String, dynamic> toJson() {
    final desc = description?.trim();
    return {
      'course_id': courseId,
      'title': title.trim(),
      'description': desc == null || desc.isEmpty ? null : desc,
      'deadline': deadline.toUtc().toIso8601String(),
      'status': status.name,
    };
  }

  Task copyWith({
    String? id,
    String? courseId,
    String? courseName,
    TaskStatus? status,
  }) => Task(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    courseName: courseName ?? this.courseName,
    title: title,
    description: description,
    deadline: deadline,
    status: status ?? this.status,
  );

  bool get isDone => status == TaskStatus.selesai;

  /// Past its deadline and not finished (FR-TASK-03).
  bool isOverdue([DateTime? now]) =>
      !isDone && deadline.isBefore(now ?? DateTime.now());

  /// Nearest deadline first; finished tasks go last (FR-TASK-02).
  static int compare(Task a, Task b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    return a.deadline.compareTo(b.deadline);
  }
}
