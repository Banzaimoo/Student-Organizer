class Course {
  const Course({required this.id, required this.name});

  final String id;
  final String name;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
