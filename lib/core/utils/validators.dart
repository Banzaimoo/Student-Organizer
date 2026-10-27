import 'package:flutter/material.dart';

class Validators {
  static String? required(String? value, [String label = 'Kolom ini']) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? email(String? value) {
    final empty = required(value, 'Email');
    if (empty != null) return empty;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return ok ? null : 'Format email tidak valid';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  /// Returns an error when [end] is not strictly after [start].
  static String? endAfterStart(TimeOfDay? start, TimeOfDay? end,
      [String message = 'Jam selesai harus setelah jam mulai']) {
    if (start == null || end == null) return null;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return e > s ? null : message;
  }
}
