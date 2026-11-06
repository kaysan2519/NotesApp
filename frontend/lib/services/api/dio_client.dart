import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../storage/token_storage_service.dart';

/// Callback ketika server mengembalikan status 401 Unauthorized (token expired / invalid).
typedef UnauthorizedCallback = Future<void> Function();

/// Klien HTTP terpusat menggunakan Dio dengan interceptor JWT Bearer Token otomatis.
class DioClient {
  final Dio _dio;
  final ITokenStorage tokenStorage;
  UnauthorizedCallback? _onUnauthorized;

  DioClient({
    required this.tokenStorage,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Perbarui baseUrl secara dinamis jika diubah melalui ApiConfig
          options.baseUrl = ApiConfig.baseUrl;

          final token = await tokenStorage.getToken();
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;

          // Jika mendapat 401 pada endpoint selain login/register, bersihkan token
          final isAuthAttempt = path.contains(ApiConfig.authLogin) ||
              path.contains(ApiConfig.authRegister);

          if (statusCode == 401 && !isAuthAttempt) {
            await tokenStorage.deleteToken();
            if (_onUnauthorized != null) {
              try {
                await _onUnauthorized!();
              } catch (e) {
                debugPrint('Error in onUnauthorized callback: $e');
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  void setUnauthorizedCallback(UnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return DioClient(tokenStorage: tokenStorage);
});
