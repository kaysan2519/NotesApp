import { describe, it, expect, beforeAll, beforeEach, afterAll } from 'vitest';
import express from 'express';
import request from 'supertest';
import { ResultSetHeader } from 'mysql2/promise';
import app from '../src/app';
import { pool, testDatabaseConnection, closeDatabasePool } from '../src/config/database';
import { env } from '../src/config/env';
import { runMigrations } from '../src/database/migrate';
import { errorMiddleware } from '../src/middleware/error.middleware';

describe('Database & Error Handling Integration Tests', () => {
  beforeAll(async () => {
    if (env.DB_NAME !== 'mynotes_test_db') {
      throw new Error(`Testing wajib menggunakan mynotes_test_db, bukan ${env.DB_NAME}`);
    }
    await runMigrations(pool, env.DB_NAME);
  });

  beforeEach(async () => {
    await pool.execute('DELETE FROM notes');
    await pool.execute('DELETE FROM users');
  });

  afterAll(async () => {
    await pool.execute('DELETE FROM notes');
    await pool.execute('DELETE FROM users');
    await closeDatabasePool();
  });

  it('1. Connection pool berfungsi dan health check melaporkan database connected', async () => {
    const isConnected = await testDatabaseConnection();
    expect(isConnected).toBe(true);

    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({
      status: 'healthy',
      database: 'connected',
    });
  });

  it('2. Foreign key constraint menjaga integritas data antara tabel notes dan users', async () => {
    // Gagal menyimpan note jika user_id tidak ada di tabel users
    await expect(
      pool.execute(
        'INSERT INTO notes (user_id, title, content, color) VALUES (?, ?, ?, ?)',
        [99999999, 'Orphan Note', 'Should fail', '#A5F3AD']
      )
    ).rejects.toThrow();

    // ON DELETE CASCADE: jika user dihapus, notes miliknya ikut terhapus otomatis
    const [userInsert] = await pool.execute<ResultSetHeader>(
      'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
      ['cascade_user', 'cascade@example.com', '$2b$12$dummyhashvalue12345678901234567890']
    );
    const userId = Number(userInsert.insertId);

    await pool.execute(
      'INSERT INTO notes (user_id, title, content, color) VALUES (?, ?, ?, ?)',
      [userId, 'Cascade Note', 'Will be deleted with user', '#A5F3AD']
    );

    await pool.execute('DELETE FROM users WHERE id = ?', [userId]);

    const [remainingNotes] = await pool.execute(
      'SELECT id FROM notes WHERE user_id = ?',
      [userId]
    );
    expect((remainingNotes as unknown[]).length).toBe(0);
  });

  it('3. Unique constraint pada kolom email di tabel users mencegah duplikasi di level database', async () => {
    await pool.execute(
      'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
      ['user1', 'unique@example.com', '$2b$12$dummyhashvalue12345678901234567890']
    );

    await expect(
      pool.execute(
        'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
        ['user2', 'unique@example.com', '$2b$12$dummyhashvalue12345678901234567890']
      )
    ).rejects.toThrow();
  });

  it('4. Centralized errorMiddleware menangani error database tanpa membocorkan query SQL', async () => {
    const testApp = express();
    testApp.get('/dup-error', (_req, _res, next) => {
      next({ code: 'ER_DUP_ENTRY', errno: 1062, message: 'Duplicate entry secret sql' });
    });
    testApp.get('/fk-error', (_req, _res, next) => {
      next({ code: 'ER_NO_REFERENCED_ROW_2', errno: 1452, message: 'Foreign key fail sql' });
    });
    testApp.get('/conn-error', (_req, _res, next) => {
      next({ code: 'ECONNREFUSED', message: 'Connection refused' });
    });
    testApp.use(errorMiddleware);

    const dupRes = await request(testApp).get('/dup-error');
    expect(dupRes.status).toBe(409);
    expect(dupRes.body.success).toBe(false);
    expect(dupRes.body.message).not.toContain('secret sql');

    const fkRes = await request(testApp).get('/fk-error');
    expect(fkRes.status).toBe(400);
    expect(fkRes.body.success).toBe(false);

    const connRes = await request(testApp).get('/conn-error');
    expect(connRes.status).toBe(503);
    expect(connRes.body.success).toBe(false);
  });
});
