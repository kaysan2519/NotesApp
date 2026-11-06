import 'package:dio/dio.dart';

/// Representasi error terstandarisasi dari REST API MyNotes.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final serverMessage = responseData['message'];
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        return ApiException(
          message: serverMessage.trim(),
          statusCode: statusCode,
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Koneksi ke server habis waktu (timeout). Periksa jaringan Anda.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Tidak dapat terhubung ke server MyNotes. Pastikan backend sedang berjalan.',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          message: error.message ?? 'Terjadi kesalahan jaringan yang tidak diketahui.',
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
