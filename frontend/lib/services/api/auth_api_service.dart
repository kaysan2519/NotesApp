import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../core/utils/api_exception.dart';
import '../../models/user_model.dart';
import '../storage/token_storage_service.dart';
import 'dio_client.dart';

/// Kontrak layanan autentikasi agar mudah di-mock pada unit & widget test.
abstract class IAuthApiService {
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout();
}

/// Implementasi REST API Authentication yang terhubung ke `/api/auth/*`.
class AuthApiService implements IAuthApiService {
  final DioClient dioClient;
  final ITokenStorage tokenStorage;

  const AuthApiService({
    required this.dioClient,
    required this.tokenStorage,
  });

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        ApiConfig.authRegister,
        data: {
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Gagal melakukan registrasi',
          statusCode: response.statusCode,
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>;

      if (token != null && token.isNotEmpty) {
        await tokenStorage.saveToken(token);
      }

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        ApiConfig.authLogin,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Gagal melakukan login',
          statusCode: response.statusCode,
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>;

      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Token autentikasi tidak ditemukan pada response server',
        );
      }

      await tokenStorage.saveToken(token);
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        ApiConfig.authMe,
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message:
              (body?['message'] as String?) ?? 'Gagal memuat profil pengguna',
          statusCode: response.statusCode,
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    await tokenStorage.deleteToken();
  }
}

final authApiServiceProvider = Provider<IAuthApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthApiService(
    dioClient: dioClient,
    tokenStorage: tokenStorage,
  );
});
