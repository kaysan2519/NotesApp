/// Validator form yang selaras dengan skema validasi Zod pada backend MyNotes.
class Validators {
  Validators._();

  static String? validateUsername(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Username wajib diisi';
    }
    if (trimmed.length < 2) {
      return 'Username minimal 2 karakter';
    }
    if (trimmed.length > 50) {
      return 'Username maksimal 50 karakter';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    if (trimmed.length > 191) {
      return 'Email maksimal 191 karakter';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Password wajib diisi';
    }
    if (raw.length < 6) {
      return 'Password minimal 6 karakter';
    }
    if (raw.length > 100) {
      return 'Password maksimal 100 karakter';
    }
    return null;
  }

  static String? validateNoteTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Judul catatan tidak boleh kosong';
    }
    if (trimmed.length > 150) {
      return 'Judul catatan maksimal 150 karakter';
    }
    return null;
  }
}
