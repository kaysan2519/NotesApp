import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes_app/main.dart';
import 'package:mynotes_app/models/note_model.dart';
import 'package:mynotes_app/models/user_model.dart';
import 'package:mynotes_app/services/api/auth_api_service.dart';
import 'package:mynotes_app/services/api/notes_api_service.dart';
import 'package:mynotes_app/services/storage/token_storage_service.dart';

class FakeTokenStorage implements ITokenStorage {
  String? token;

  FakeTokenStorage({this.token});

  @override
  Future<void> saveToken(String newToken) async {
    token = newToken;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

class FakeAuthApiService implements IAuthApiService {
  final FakeTokenStorage storage;
  UserModel currentUser = const UserModel(
    id: 1,
    username: 'jessica',
    email: 'jessica@example.com',
  );

  FakeAuthApiService(this.storage);

  @override
  Future<UserModel> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await storage.saveToken('fake_jwt_token');
    return currentUser;
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    currentUser = UserModel(id: 2, username: username, email: email);
    await storage.saveToken('fake_jwt_token');
    return currentUser;
  }

  @override
  Future<void> logout() async {
    await storage.deleteToken();
  }
}

class FakeNotesApiService implements INotesApiService {
  final List<NoteModel> _notes = [
    NoteModel(
      id: 1,
      userId: 1,
      title: 'Business Team Meeting',
      content: 'Persiapan meeting bersama tim.',
      color: '#A5F3AD',
      isPinned: true,
      isPrivate: true,
      createdAt: DateTime(2026, 11, 6, 8, 0),
      updatedAt: DateTime(2026, 11, 6, 8, 0),
    ),
  ];

  @override
  Future<List<NoteModel>> getNotes({
    String? search,
    bool? isPinned,
    String? color,
  }) async {
    Iterable<NoteModel> filtered = _notes;
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where(
        (n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q),
      );
    }
    if (isPinned != null) {
      filtered = filtered.where((n) => n.isPinned == isPinned);
    }
    return filtered.toList();
  }

  @override
  Future<NoteModel> getNoteById(int id) async {
    return _notes.firstWhere((n) => n.id == id);
  }

  @override
  Future<NoteModel> createNote({
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  }) async {
    final created = NoteModel(
      id: _notes.length + 1,
      userId: 1,
      title: title,
      content: content,
      color: color,
      isPinned: isPinned,
      isPrivate: isPrivate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.insert(0, created);
    return created;
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
    final index = _notes.indexWhere((n) => n.id == id);
    final updated = _notes[index].copyWith(
      title: title,
      content: content,
      color: color,
      isPinned: isPinned,
      isPrivate: isPrivate,
      updatedAt: DateTime.now(),
    );
    _notes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteNote(int id) async {
    _notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<NoteModel> updatePin({
    required int id,
    required bool isPinned,
  }) async {
    final index = _notes.indexWhere((n) => n.id == id);
    final updated = _notes[index].copyWith(isPinned: isPinned);
    _notes[index] = updated;
    return updated;
  }

  @override
  Future<NoteModel> updatePrivacy({
    required int id,
    required bool isPrivate,
  }) async {
    final index = _notes.indexWhere((n) => n.id == id);
    final updated = _notes[index].copyWith(isPrivate: isPrivate);
    _notes[index] = updated;
    return updated;
  }
}

void main() {
  testWidgets(
      'Unauthenticated user redirects to Login, validates form, and can sign in to Home Dashboard',
      (WidgetTester tester) async {
    final storage = FakeTokenStorage();
    final fakeAuth = FakeAuthApiService(storage);
    final fakeNotes = FakeNotesApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authApiServiceProvider.overrideWithValue(fakeAuth),
          notesApiServiceProvider.overrideWithValue(fakeNotes),
        ],
        child: const MyNotesApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Berada di halaman Login
    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Uji validasi ketika form kosong
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);

    // Isi email dan password lalu Sign In
    await tester.enterText(
      find.byType(TextFormField).first,
      'jessica@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'password123',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Berhasil masuk ke Home / My Notes dan menampilkan catatan dari API
    expect(find.text('My Notes'), findsOneWidget);
    expect(find.text('Business Team Meeting'), findsOneWidget);
    expect(find.text('Add New Note'), findsOneWidget);
  });

  testWidgets(
      'Authenticated user auto-logins to Dashboard and can create, view detail, and delete a note',
      (WidgetTester tester) async {
    final storage = FakeTokenStorage(token: 'existing_valid_jwt');
    final fakeAuth = FakeAuthApiService(storage);
    final fakeNotes = FakeNotesApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authApiServiceProvider.overrideWithValue(fakeAuth),
          notesApiServiceProvider.overrideWithValue(fakeNotes),
        ],
        child: const MyNotesApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Auto-login langsung menuju Home Screen
    expect(find.text('My Notes'), findsOneWidget);
    expect(find.text('Business Team Meeting'), findsOneWidget);

    // Navigasi ke Create Note
    await tester.tap(find.text('Add New Note'));
    await tester.pumpAndSettle();
    expect(find.text('Create New Note'), findsOneWidget);

    // Isi judul dan isi catatan baru
    await tester.enterText(
      find.byType(TextFormField).first,
      'Design System Review',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Pastel cards and pill buttons verified.',
    );

    await tester.tap(find.text('Save Note'));
    await tester.pumpAndSettle();

    // Kembali ke Home Screen dan catatan baru muncul di daftar
    expect(find.text('Design System Review'), findsOneWidget);

    // Buka detail catatan
    await tester.tap(find.text('Design System Review'));
    await tester.pumpAndSettle();
    expect(find.text('Pastel cards and pill buttons verified.'), findsOneWidget);
    expect(find.text('Edit Note'), findsOneWidget);
  });
}
