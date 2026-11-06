import 'package:flutter/material.dart';

/// Opsi warna catatan yang selaras 100% dengan `backend/src/config/note-colors.ts`.
class NoteColorOption {
  final String name;
  final String hex;
  final Color color;

  const NoteColorOption({
    required this.name,
    required this.hex,
    required this.color,
  });
}

/// Sistem palet warna MyNotes sesuai referensi desain.
class AppColors {
  AppColors._();

  // Background & Surface
  static const Color creamBackground = Color(0xFFFDFBF6);
  static const Color creamSurface = Color(0xFFF6F2E9);
  static const Color white = Color(0xFFFFFFFF);

  // Primary & Action Colors
  static const Color mintGreen = Color(0xFFA5F3AD);
  static const Color darkButton = Color(0xFF202020);
  static const Color darkSurface = Color(0xFF2A2A2A);

  // Note Card Pastel Palette (sesuai backend MySQL & validasi Zod)
  static const Color lavender = Color(0xFFD8A7F5);
  static const Color yellow = Color(0xFFF6DB59);
  static const Color pink = Color(0xFFF2A3A6);
  static const Color turquoise = Color(0xFF70DDC7);
  static const Color blue = Color(0xFF83BCEB);
  static const Color gray = Color(0xFFD9D9D9);

  // Typography & UI Borders
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF686763);
  static const Color textMuted = Color(0xFF9A9892);
  static const Color borderLight = Color(0xFFE6E1D6);
  static const Color error = Color(0xFFD9383A);
  static const Color success = Color(0xFF2E7D32);

  // Default Hex
  static const String defaultNoteHex = '#A5F3AD';

  /// Daftar lengkap pilihan warna kartu catatan untuk Color Picker.
  static const List<NoteColorOption> noteColorOptions = [
    NoteColorOption(name: 'Mint Green', hex: '#A5F3AD', color: mintGreen),
    NoteColorOption(name: 'Lavender', hex: '#D8A7F5', color: lavender),
    NoteColorOption(name: 'Yellow', hex: '#F6DB59', color: yellow),
    NoteColorOption(name: 'Pink', hex: '#F2A3A6', color: pink),
    NoteColorOption(name: 'Turquoise', hex: '#70DDC7', color: turquoise),
    NoteColorOption(name: 'Blue', hex: '#83BCEB', color: blue),
    NoteColorOption(name: 'Gray', hex: '#D9D9D9', color: gray),
    NoteColorOption(name: 'White', hex: '#FFFFFF', color: white),
  ];

  /// Mengonversi string kode Hex dari backend (misal `#A5F3AD`) menjadi objek [Color].
  static Color fromHex(String? hexString) {
    if (hexString == null || hexString.trim().isEmpty) {
      return mintGreen;
    }
    final normalized = hexString.trim().toUpperCase();
    for (final option in noteColorOptions) {
      if (option.hex == normalized) {
        return option.color;
      }
    }
    final cleaned = normalized.replaceAll('#', '');
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }
    return mintGreen;
  }

  /// Mendapatkan nama warna yang ramah pengguna berdasarkan kode hex.
  static String nameFromHex(String? hexString) {
    if (hexString == null) return 'Mint Green';
    final normalized = hexString.trim().toUpperCase();
    for (final option in noteColorOptions) {
      if (option.hex == normalized) {
        return option.name;
      }
    }
    return 'Mint Green';
  }
}
