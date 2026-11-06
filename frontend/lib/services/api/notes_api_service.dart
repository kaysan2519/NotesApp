import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../core/utils/api_exception.dart';
import '../../models/note_model.dart';
import 'dio_client.dart';

/// Kontrak layanan API Notes agar mudah di-mock pada unit & widget test.
abstract class INotesApiService {
  Future<List<NoteModel>> getNotes({
    String? search,
    bool? isPinned,
    String? color,
  });

  Future<NoteModel> getNoteById(int id);

  Future<NoteModel> createNote({
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  });

  Future<NoteModel> updateNote({
    required int id,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  });

  Future<void> deleteNote(int id);

  Future<NoteModel> updatePin({
    required int id,
    required bool isPinned,
  });

  Future<NoteModel> updatePrivacy({
    required int id,
    required bool isPrivate,
  });
}

/// Implementasi REST API Notes yang terhubung langsung ke `/api/notes/*`.
class NotesApiService implements INotesApiService {
  final DioClient dioClient;

  const NotesApiService({required this.dioClient});

  @override
  Future<List<NoteModel>> getNotes({
    String? search,
    bool? isPinned,
    String? color,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (isPinned != null) {
        queryParams['is_pinned'] = isPinned.toString();
      }
      if (color != null && color.trim().isNotEmpty) {
        queryParams['color'] = color.trim().toUpperCase();
      }

      final response = await dioClient.dio.get<Map<String, dynamic>>(
        ApiConfig.notes,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Gagal memuat daftar catatan',
          statusCode: response.statusCode,
        );
      }

      final rawList = body['data'] as List<dynamic>;
      return rawList
          .map((item) => NoteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<NoteModel> getNoteById(int id) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        ApiConfig.noteById(id),
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Catatan tidak ditemukan',
          statusCode: response.statusCode,
        );
      }

      return NoteModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<NoteModel> createNote({
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        ApiConfig.notes,
        data: {
          'title': title.trim(),
          'content': content,
          'color': color.trim().toUpperCase(),
          'is_pinned': isPinned,
          'is_private': isPrivate,
        },
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Gagal membuat catatan baru',
          statusCode: response.statusCode,
        );
      }

      return NoteModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<NoteModel> updateNote({
    required int id,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  }) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>(
        ApiConfig.noteById(id),
        data: {
          'title': title.trim(),
          'content': content,
          'color': color.trim().toUpperCase(),
          'is_pinned': isPinned,
          'is_private': isPrivate,
        },
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Gagal memperbarui catatan',
          statusCode: response.statusCode,
        );
      }

      return NoteModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>(
        ApiConfig.noteById(id),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw ApiException(
          message: (body?['message'] as String?) ?? 'Gagal menghapus catatan',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<NoteModel> updatePin({
    required int id,
    required bool isPinned,
  }) async {
    try {
      final response = await dioClient.dio.patch<Map<String, dynamic>>(
        ApiConfig.notePin(id),
        data: {'is_pinned': isPinned},
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message:
              (body?['message'] as String?) ?? 'Gagal mengubah status pin catatan',
          statusCode: response.statusCode,
        );
      }

      return NoteModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<NoteModel> updatePrivacy({
    required int id,
    required bool isPrivate,
  }) async {
    try {
      final response = await dioClient.dio.patch<Map<String, dynamic>>(
        ApiConfig.notePrivacy(id),
        data: {'is_private': isPrivate},
      );

      final body = response.data;
      if (body == null || body['success'] != true || body['data'] == null) {
        throw ApiException(
          message: (body?['message'] as String?) ??
              'Gagal mengubah pengaturan privasi catatan',
          statusCode: response.statusCode,
        );
      }

      return NoteModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final notesApiServiceProvider = Provider<INotesApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotesApiService(dioClient: dioClient);
});
