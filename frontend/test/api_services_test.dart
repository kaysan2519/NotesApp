import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes_app/core/constants/app_colors.dart';
import 'package:mynotes_app/core/utils/validators.dart';
import 'package:mynotes_app/services/api/auth_api_service.dart';
import 'package:mynotes_app/services/api/dio_client.dart';
import 'package:mynotes_app/services/api/notes_api_service.dart';
import 'package:mynotes_app/services/storage/token_storage_service.dart';

class InMemoryTokenStorage implements ITokenStorage {
  String? _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}

typedef MockHandler = ResponseBody Function(RequestOptions options);

class MockHttpAdapter implements HttpClientAdapter {
  final MockHandler handler;
  RequestOptions? lastRequest;

  MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('Token Storage, DioClient JWT Interceptor & 401 Handling Tests', () {
    test('TokenStorage saves, retrieves, and deletes JWT token', () async {
      final storage = InMemoryTokenStorage();
      expect(await storage.getToken(), isNull);

      await storage.saveToken('jwt_sample_123');
      expect(await storage.getToken(), 'jwt_sample_123');

      await storage.deleteToken();
      expect(await storage.getToken(), isNull);
    });

    test('DioClient attaches Authorization Bearer header when token exists',
        () async {
      final storage = InMemoryTokenStorage();
      await storage.saveToken('secret_jwt_token');

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      final adapter = MockHttpAdapter((options) {
        return jsonResponse({
          'success': true,
          'message': 'OK',
          'data': [],
        });
      });
      dio.httpClientAdapter = adapter;

      final client = DioClient(tokenStorage: storage, dio: dio);
      await client.dio.get<Map<String, dynamic>>('/notes');

      expect(
        adapter.lastRequest?.headers['Authorization'],
        'Bearer secret_jwt_token',
      );
    });

    test('DioClient clears token and triggers callback on 401 Unauthorized',
        () async {
      final storage = InMemoryTokenStorage();
      await storage.saveToken('expired_jwt_token');
      bool callbackTriggered = false;

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      dio.httpClientAdapter = MockHttpAdapter((options) {
        return jsonResponse(
          {
            'success': false,
            'message': 'Token autentikasi telah kedaluwarsa',
            'data': null,
          },
          statusCode: 401,
        );
      });

      final client = DioClient(tokenStorage: storage, dio: dio);
      client.setUnauthorizedCallback(() async {
        callbackTriggered = true;
      });

      await expectLater(
        client.dio.get<Map<String, dynamic>>('/notes'),
        throwsA(isA<DioException>()),
      );

      expect(await storage.getToken(), isNull);
      expect(callbackTriggered, isTrue);
    });
  });

  group('AuthApiService & NotesApiService Contract Tests', () {
    test('AuthApiService login stores JWT token and returns UserModel',
        () async {
      final storage = InMemoryTokenStorage();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      dio.httpClientAdapter = MockHttpAdapter((options) {
        expect(options.path, '/auth/login');
        expect(options.method, 'POST');
        return jsonResponse({
          'success': true,
          'message': 'Login successful',
          'data': {
            'user': {
              'id': 1,
              'username': 'jessica',
              'email': 'jessica@example.com',
            },
            'token': 'jwt_login_token_abc',
          },
        });
      });

      final client = DioClient(tokenStorage: storage, dio: dio);
      final authService = AuthApiService(
        dioClient: client,
        tokenStorage: storage,
      );

      final user = await authService.login(
        email: 'jessica@example.com',
        password: 'password123',
      );

      expect(user.id, 1);
      expect(user.username, 'jessica');
      expect(user.email, 'jessica@example.com');
      expect(await storage.getToken(), 'jwt_login_token_abc');
    });

    test('NotesApiService performs CRUD, search, pin, and privacy operations',
        () async {
      final storage = InMemoryTokenStorage();
      await storage.saveToken('valid_user_jwt');

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      final adapter = MockHttpAdapter((options) {
        if (options.method == 'GET' && options.path == '/notes') {
          return jsonResponse({
            'success': true,
            'message': 'Notes retrieved successfully',
            'data': [
              {
                'id': 10,
                'user_id': 1,
                'title': 'Team Sync',
                'content': 'Prepare slides',
                'color': '#A5F3AD',
                'is_pinned': true,
                'is_private': true,
                'created_at': '2026-11-06T03:00:00.000Z',
                'updated_at': '2026-11-06T03:00:00.000Z',
              }
            ],
          });
        }
        if (options.method == 'POST' && options.path == '/notes') {
          return jsonResponse(
            {
              'success': true,
              'message': 'Note created successfully',
              'data': {
                'id': 11,
                'user_id': 1,
                'title': 'New Idea',
                'content': 'Build Flutter UI',
                'color': '#D8A7F5',
                'is_pinned': false,
                'is_private': true,
                'created_at': '2026-11-06T04:00:00.000Z',
                'updated_at': '2026-11-06T04:00:00.000Z',
              },
            },
            statusCode: 201,
          );
        }
        if (options.method == 'PATCH' && options.path == '/notes/11/pin') {
          return jsonResponse({
            'success': true,
            'message': 'Note pin status updated successfully',
            'data': {
              'id': 11,
              'user_id': 1,
              'title': 'New Idea',
              'content': 'Build Flutter UI',
              'color': '#D8A7F5',
              'is_pinned': true,
              'is_private': true,
              'created_at': '2026-11-06T04:00:00.000Z',
              'updated_at': '2026-11-06T04:05:00.000Z',
            },
          });
        }
        if (options.method == 'DELETE' && options.path == '/notes/11') {
          return jsonResponse({
            'success': true,
            'message': 'Note deleted successfully',
            'data': null,
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'},
            statusCode: 404);
      });
      dio.httpClientAdapter = adapter;

      final client = DioClient(tokenStorage: storage, dio: dio);
      final notesService = NotesApiService(dioClient: client);

      final notes = await notesService.getNotes(search: 'Team', isPinned: true);
      expect(notes.length, 1);
      expect(notes.first.title, 'Team Sync');
      expect(adapter.lastRequest?.queryParameters['search'], 'Team');
      expect(adapter.lastRequest?.queryParameters['is_pinned'], 'true');

      final created = await notesService.createNote(
        title: 'New Idea',
        content: 'Build Flutter UI',
        color: '#D8A7F5',
        isPinned: false,
        isPrivate: true,
      );
      expect(created.id, 11);
      expect(created.color, '#D8A7F5');

      final pinned = await notesService.updatePin(id: 11, isPinned: true);
      expect(pinned.isPinned, isTrue);

      await notesService.deleteNote(11);
      expect(adapter.lastRequest?.method, 'DELETE');
    });
  });

  group('Validators & AppColors Design System Tests', () {
    test('Validators enforce backend Zod constraints', () {
      expect(Validators.validateUsername('a'), isNotNull);
      expect(Validators.validateUsername('jessica'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail('jessica@example.com'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validateNoteTitle('   '), isNotNull);
      expect(Validators.validateNoteTitle('Meeting Notes'), isNull);
    });

    test('AppColors maps all 8 backend hex colors accurately', () {
      expect(AppColors.fromHex('#A5F3AD'), AppColors.mintGreen);
      expect(AppColors.fromHex('#D8A7F5'), AppColors.lavender);
      expect(AppColors.fromHex('#F6DB59'), AppColors.yellow);
      expect(AppColors.fromHex('#F2A3A6'), AppColors.pink);
      expect(AppColors.fromHex('#70DDC7'), AppColors.turquoise);
      expect(AppColors.fromHex('#83BCEB'), AppColors.blue);
      expect(AppColors.fromHex('#D9D9D9'), AppColors.gray);
      expect(AppColors.fromHex('#FFFFFF'), AppColors.white);
    });
  });
}
