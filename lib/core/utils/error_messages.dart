import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any exception into a short Indonesian message for the UI (NFR-08).
String friendlyError(Object e) {
  if (e is PostgrestException) {
    if (e.code == '23505') return 'Data yang sama sudah ada.';
    if (e.code == '23514') return 'Data tidak valid. Periksa kembali isian.';
    if (e.code == 'PGRST116') return 'Data tidak ditemukan.';
    return 'Terjadi kesalahan pada server. Coba lagi.';
  }
  if (e is AuthException) return 'Sesi berakhir. Silakan masuk kembali.';
  return 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
}
