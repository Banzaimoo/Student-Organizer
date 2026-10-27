import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile.dart';

class AuthRepository {
  final _db = Supabase.instance.client;

  Session? get currentSession => _db.auth.currentSession;
  Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) =>
      _db.auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> signUp(String fullName, String email, String password) =>
      _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

  Future<void> signOut() => _db.auth.signOut();

  Future<Profile> fetchProfile() async {
    final row = await _db
        .from('profiles')
        .select()
        .eq('id', _db.auth.currentUser!.id)
        .single();
    return Profile.fromJson(row);
  }

  Future<void> updateProfile({
    required String fullName,
    String? nim,
    String? studyProgram,
  }) =>
      _db.from('profiles').update({
        'full_name': fullName.trim(),
        'nim': _blankToNull(nim),
        'study_program': _blankToNull(studyProgram),
      }).eq('id', _db.auth.currentUser!.id);

  static String? _blankToNull(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
