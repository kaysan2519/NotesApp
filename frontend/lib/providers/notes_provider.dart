import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/api_exception.dart';
import '../models/note_model.dart';
import '../services/api/notes_api_service.dart';

class NotesState {
  final List<NoteModel> notes;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String searchQuery;
  final bool onlyPinned;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.searchQuery = '',
    this.onlyPinned = false,
  });

  NotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    bool? onlyPinned,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      onlyPinned: onlyPinned ?? this.onlyPinned,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final INotesApiService notesApiService;

  NotesNotifier({required this.notesApiService}) : super(const NotesState());

  /// Mengambil seluruh daftar catatan dari backend MySQL sesuai filter aktif.
  Future<void> fetchNotes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final fetched = await notesApiService.getNotes(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        isPinned: state.onlyPinned ? true : null,
      );
      state = state.copyWith(
        notes: fetched,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar catatan dari server.',
      );
    }
  }

  /// Mengubah kata kunci pencarian dan memuat ulang daftar catatan dari API.
  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    await fetchNotes();
  }

  /// Mengaktifkan atau menonaktifkan filter khusus catatan yang di-pin.
  Future<void> setOnlyPinned(bool onlyPinned) async {
    if (state.onlyPinned == onlyPinned) return;
    state = state.copyWith(onlyPinned: onlyPinned);
    await fetchNotes();
  }

  /// Mengambil detail satu catatan langsung dari API.
  Future<NoteModel?> fetchNoteDetail(int id) async {
    try {
      final note = await notesApiService.getNoteById(id);
      _replaceNoteInList(note);
      return note;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }

  /// Membuat catatan baru melalui REST API.
  Future<NoteModel?> createNote({
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await notesApiService.createNote(
        title: title,
        content: content,
        color: color,
        isPinned: isPinned,
        isPrivate: isPrivate,
      );
      state = state.copyWith(isSaving: false);
      await fetchNotes();
      return created;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal menyimpan catatan baru.',
      );
      return null;
    }
  }

  /// Memperbarui catatan yang sudah ada melalui REST API.
  Future<NoteModel?> updateNote({
    required int id,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isPrivate,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await notesApiService.updateNote(
        id: id,
        title: title,
        content: content,
        color: color,
        isPinned: isPinned,
        isPrivate: isPrivate,
      );
      state = state.copyWith(isSaving: false);
      await fetchNotes();
      return updated;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal memperbarui catatan.',
      );
      return null;
    }
  }

  /// Menghapus catatan dari database melalui REST API.
  Future<bool> deleteNote(int id) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await notesApiService.deleteNote(id);
      final remaining = state.notes.where((n) => n.id != id).toList();
      state = state.copyWith(
        notes: remaining,
        isSaving: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal menghapus catatan.',
      );
      return false;
    }
  }

  /// Mengubah status pin catatan melalui `PATCH /api/notes/:id/pin`.
  Future<NoteModel?> togglePin(NoteModel note) async {
    try {
      final updated = await notesApiService.updatePin(
        id: note.id,
        isPinned: !note.isPinned,
      );
      await fetchNotes();
      return updated;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }

  /// Mengubah status private catatan melalui `PATCH /api/notes/:id/privacy`.
  Future<NoteModel?> togglePrivacy(NoteModel note) async {
    try {
      final updated = await notesApiService.updatePrivacy(
        id: note.id,
        isPrivate: !note.isPrivate,
      );
      _replaceNoteInList(updated);
      return updated;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }

  void _replaceNoteInList(NoteModel updated) {
    final index = state.notes.indexWhere((n) => n.id == updated.id);
    if (index != -1) {
      final copy = [...state.notes];
      copy[index] = updated;
      state = state.copyWith(notes: copy);
    }
  }

  void clearState() {
    state = const NotesState();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final notesApiService = ref.watch(notesApiServiceProvider);
  return NotesNotifier(notesApiService: notesApiService);
});
