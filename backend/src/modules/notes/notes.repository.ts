import { ResultSetHeader } from 'mysql2/promise';
import { pool } from '../../config/database';
import {
  CreateNoteInput,
  NoteItem,
  NoteRow,
  NotesQueryFilter,
  UpdateNoteInput,
} from './notes.types';

export class NotesRepository {
  /**
   * Mengonversi baris database MySQL (TINYINT boolean & BIGINT id) menjadi objek NoteItem standar.
   */
  private mapRowToNote(row: NoteRow): NoteItem {
    return {
      id: Number(row.id),
      user_id: Number(row.user_id),
      title: row.title,
      content: row.content ?? '',
      color: row.color,
      is_pinned: Boolean(row.is_pinned),
      is_private: Boolean(row.is_private),
      created_at: row.created_at,
      updated_at: row.updated_at,
    };
  }

  /**
   * Membuat catatan baru untuk pengguna tertentu.
   */
  public async create(userId: number, data: CreateNoteInput): Promise<NoteItem> {
    const [result] = await pool.execute<ResultSetHeader>(
      `INSERT INTO notes (user_id, title, content, color, is_pinned, is_private)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        userId,
        data.title,
        data.content,
        data.color,
        data.is_pinned ? 1 : 0,
        data.is_private ? 1 : 0,
      ]
    );

    const createdId = Number(result.insertId);
    const createdNote = await this.findByIdAndUser(createdId, userId);

    if (!createdNote) {
      throw new Error('Gagal membaca kembali catatan yang baru dibuat');
    }

    return createdNote;
  }

  /**
   * Mengambil seluruh catatan milik pengguna yang sedang login.
   * Mendukung pencarian (title & content), filter warna, dan filter pinned.
   * Diurutkan berdasarkan: is_pinned DESC, updated_at DESC, id DESC.
   */
  public async findAllByUser(
    userId: number,
    filter: NotesQueryFilter = {}
  ): Promise<NoteItem[]> {
    const conditions: string[] = ['user_id = ?'];
    const params: Array<string | number> = [userId];

    if (filter.search && filter.search.trim().length > 0) {
      const searchPattern = `%${filter.search.trim()}%`;
      conditions.push('(title LIKE ? OR content LIKE ?)');
      params.push(searchPattern, searchPattern);
    }

    if (filter.color) {
      conditions.push('color = ?');
      params.push(filter.color);
    }

    if (typeof filter.is_pinned === 'boolean') {
      conditions.push('is_pinned = ?');
      params.push(filter.is_pinned ? 1 : 0);
    }

    const whereClause = conditions.join(' AND ');
    const sql = `
      SELECT id, user_id, title, content, color, is_pinned, is_private, created_at, updated_at
      FROM notes
      WHERE ${whereClause}
      ORDER BY is_pinned DESC, updated_at DESC, id DESC
    `;

    const [rows] = await pool.execute<NoteRow[]>(sql, params);
    return rows.map((row) => this.mapRowToNote(row));
  }

  /**
   * Mengambil detail satu catatan berdasarkan ID dan memastikan kepemilikan (user_id).
   */
  public async findByIdAndUser(
    noteId: number,
    userId: number
  ): Promise<NoteItem | null> {
    const [rows] = await pool.execute<NoteRow[]>(
      `SELECT id, user_id, title, content, color, is_pinned, is_private, created_at, updated_at
       FROM notes
       WHERE id = ? AND user_id = ?
       LIMIT 1`,
      [noteId, userId]
    );

    const row = rows[0];
    return row ? this.mapRowToNote(row) : null;
  }

  /**
   * Memperbarui catatan berdasarkan ID dan user_id pemilik.
   */
  public async updateByIdAndUser(
    noteId: number,
    userId: number,
    data: UpdateNoteInput
  ): Promise<NoteItem | null> {
    const fields: string[] = [];
    const params: Array<string | number> = [];

    if (data.title !== undefined) {
      fields.push('title = ?');
      params.push(data.title);
    }
    if (data.content !== undefined) {
      fields.push('content = ?');
      params.push(data.content);
    }
    if (data.color !== undefined) {
      fields.push('color = ?');
      params.push(data.color);
    }
    if (data.is_pinned !== undefined) {
      fields.push('is_pinned = ?');
      params.push(data.is_pinned ? 1 : 0);
    }
    if (data.is_private !== undefined) {
      fields.push('is_private = ?');
      params.push(data.is_private ? 1 : 0);
    }

    fields.push('updated_at = CURRENT_TIMESTAMP');

    const sql = `
      UPDATE notes
      SET ${fields.join(', ')}
      WHERE id = ? AND user_id = ?
    `;

    params.push(noteId, userId);

    const [result] = await pool.execute<ResultSetHeader>(sql, params);
    if (result.affectedRows === 0) {
      return null;
    }

    return this.findByIdAndUser(noteId, userId);
  }

  /**
   * Menghapus catatan secara permanen berdasarkan ID dan user_id pemilik.
   */
  public async deleteByIdAndUser(
    noteId: number,
    userId: number
  ): Promise<boolean> {
    const [result] = await pool.execute<ResultSetHeader>(
      'DELETE FROM notes WHERE id = ? AND user_id = ?',
      [noteId, userId]
    );

    return result.affectedRows > 0;
  }
}

export const notesRepository = new NotesRepository();
