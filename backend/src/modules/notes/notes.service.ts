import { notesRepository } from './notes.repository';
import {
  CreateNoteInput,
  NoteItem,
  NotesQueryFilter,
  UpdateNoteInput,
} from './notes.types';
import { AppError } from '../../utils/response.util';

export class NotesService {
  /**
   * Membuat catatan baru milik pengguna yang sedang login.
   */
  public async createNote(
    userId: number,
    input: CreateNoteInput
  ): Promise<NoteItem> {
    return notesRepository.create(userId, input);
  }

  /**
   * Mengambil semua catatan milik pengguna dengan dukungan pencarian & filter.
   */
  public async getAllNotes(
    userId: number,
    filter: NotesQueryFilter
  ): Promise<NoteItem[]> {
    return notesRepository.findAllByUser(userId, filter);
  }

  /**
   * Mengambil detail satu catatan milik pengguna.
   * Jika catatan tidak ada atau milik pengguna lain, kembalikan 404 tanpa membocorkan informasi pemilik.
   */
  public async getNoteById(userId: number, noteId: number): Promise<NoteItem> {
    const note = await notesRepository.findByIdAndUser(noteId, userId);
    if (!note) {
      throw new AppError('Catatan tidak ditemukan', 404);
    }
    return note;
  }

  /**
   * Memperbarui isi atau pengaturan catatan milik pengguna.
   */
  public async updateNote(
    userId: number,
    noteId: number,
    input: UpdateNoteInput
  ): Promise<NoteItem> {
    const updated = await notesRepository.updateByIdAndUser(
      noteId,
      userId,
      input
    );
    if (!updated) {
      throw new AppError('Catatan tidak ditemukan', 404);
    }
    return updated;
  }

  /**
   * Menghapus catatan milik pengguna dari database.
   */
  public async deleteNote(userId: number, noteId: number): Promise<void> {
    const deleted = await notesRepository.deleteByIdAndUser(noteId, userId);
    if (!deleted) {
      throw new AppError('Catatan tidak ditemukan', 404);
    }
  }

  /**
   * Mengubah status pin pada catatan milik pengguna.
   */
  public async updateNotePin(
    userId: number,
    noteId: number,
    isPinned: boolean
  ): Promise<NoteItem> {
    return this.updateNote(userId, noteId, { is_pinned: isPinned });
  }

  /**
   * Mengubah status privasi (is_private) pada catatan milik pengguna.
   */
  public async updateNotePrivacy(
    userId: number,
    noteId: number,
    isPrivate: boolean
  ): Promise<NoteItem> {
    return this.updateNote(userId, noteId, { is_private: isPrivate });
  }
}

export const notesService = new NotesService();
