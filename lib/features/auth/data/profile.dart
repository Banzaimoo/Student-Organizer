class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.nim,
    this.studyProgram,
  });

  final String id;
  final String fullName;
  final String? nim;
  final String? studyProgram;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: (json['full_name'] as String?) ?? '',
        nim: json['nim'] as String?,
        studyProgram: json['study_program'] as String?,
      );
}
