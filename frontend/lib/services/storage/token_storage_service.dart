import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kontrak penyimpanan token JWT agar mudah diuji (mockable pada unit/widget test).
abstract class ITokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

/// Implementasi penyimpanan JWT aman menggunakan `flutter_secure_storage`.
/// Tidak pernah menyimpan password pengguna secara lokal.
class TokenStorageService implements ITokenStorage {
  static const String _jwtKey = 'mynotes_jwt_auth_token';

  final FlutterSecureStorage _secureStorage;

  const TokenStorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _jwtKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return _secureStorage.read(key: _jwtKey);
  }

  @override
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _jwtKey);
  }
}

final tokenStorageProvider = Provider<ITokenStorage>((ref) {
  return const TokenStorageService();
});
