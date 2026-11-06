import { ResultSetHeader } from 'mysql2/promise';
import { pool } from '../../config/database';
import { PublicUser, UserRow } from './auth.types';

export class AuthRepository {
  /**
   * Mencari user berdasarkan alamat email (termasuk hash password untuk verifikasi login).
   */
  public async findByEmail(email: string): Promise<UserRow | null> {
    const [rows] = await pool.execute<UserRow[]>(
      'SELECT id, username, email, password, created_at, updated_at FROM users WHERE email = ? LIMIT 1',
      [email]
    );
    return rows[0] ?? null;
  }

  /**
   * Mencari profil publik user berdasarkan ID (tanpa kolom password).
   */
  public async findById(id: number): Promise<PublicUser | null> {
    const [rows] = await pool.execute<UserRow[]>(
      'SELECT id, username, email, created_at, updated_at FROM users WHERE id = ? LIMIT 1',
      [id]
    );
    const user = rows[0];
    if (!user) {
      return null;
    }
    return {
      id: Number(user.id),
      username: user.username,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at,
    };
  }

  /**
   * Menyimpan pengguna baru ke dalam tabel users.
   */
  public async createUser(
    username: string,
    email: string,
    passwordHash: string
  ): Promise<PublicUser> {
    const [result] = await pool.execute<ResultSetHeader>(
      'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
      [username, email, passwordHash]
    );

    const createdId = Number(result.insertId);
    const createdUser = await this.findById(createdId);

    if (!createdUser) {
      return {
        id: createdId,
        username,
        email,
      };
    }

    return createdUser;
  }
}

export const authRepository = new AuthRepository();
