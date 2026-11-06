import 'package:flutter/foundation.dart';

/// Konfigurasi terpusat untuk koneksi REST API MyNotes.
/// Dapat diubah melalui `--dart-define=API_BASE_URL=http://192.168.x.x:3000/api`
/// atau menggunakan [ApiConfig.setCustomBaseUrl] saat runtime.
class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String? _customBaseUrl;

  /// Mengatur Base URL secara manual (misalnya untuk perangkat fisik di jaringan LAN).
  static void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customBaseUrl = null;
    } else {
      _customBaseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    }
  }

  /// Mendapatkan Base URL aktif sesuai platform yang berjalan.
  /// - Android Emulator otomatis menggunakan `http://10.0.2.2:3000/api`
  /// - Web / Desktop / iOS Simulator menggunakan `http://localhost:3000/api`
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Endpoint Paths
  static const String health = '/health';
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String notes = '/notes';

  static String noteById(int id) => '/notes/$id';
  static String notePin(int id) => '/notes/$id/pin';
  static String notePrivacy(int id) => '/notes/$id/privacy';
}
