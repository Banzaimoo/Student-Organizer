import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/profile.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  bool loading = false;
  String? error;
  Profile? profile;

  /// Runs [action], toggling [loading] and storing a friendly [error].
  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      error = _authMessage(e);
      return false;
    } on PostgrestException {
      error = 'Terjadi kesalahan pada server. Coba lagi.';
      return false;
    } catch (_) {
      error = 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email, password));

  Future<bool> signUp(String fullName, String email, String password) =>
      _run(() => _repo.signUp(fullName, email, password));

  Future<void> signOut() async {
    profile = null;
    await _run(_repo.signOut);
  }

  Future<bool> loadProfile() => _run(() async {
        profile = await _repo.fetchProfile();
      });

  Future<bool> saveProfile({
    required String fullName,
    String? nim,
    String? studyProgram,
  }) =>
      _run(() async {
        await _repo.updateProfile(
          fullName: fullName,
          nim: nim,
          studyProgram: studyProgram,
        );
        profile = await _repo.fetchProfile();
      });

  void clearError() {
    error = null;
    notifyListeners();
  }

  static String _authMessage(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'Email sudah terdaftar';
    }
    if (m.contains('email not confirmed')) return 'Email belum dikonfirmasi';
    if (m.contains('password')) return 'Password tidak memenuhi syarat';
    if (m.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
    return 'Autentikasi gagal. Coba lagi.';
  }
}
