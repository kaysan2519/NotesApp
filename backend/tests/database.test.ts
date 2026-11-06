import { describe, it, expect, beforeAll, beforeEach, afterAll } from 'vitest';
import express from 'express';
import request from 'supertest';
import { ResultSetHeader } from 'mysql2/promise';
import app from '../src/app';
import {
  pool,
  testDatabaseConnection,
  closeDatabasePool,
  buildDatabaseSslOptions,
  buildDatabasePoolOptions,
} from '../src/config/database';
import { env, parseEnv } from '../src/config/env';
import { runMigrations } from '../src/database/migrate';
import { errorMiddleware } from '../src/middleware/error.middleware';

const DUMMY_PEM_CERT = [
  '-----BEGIN CERTIFICATE-----',
  'MIIBszCCAVugAwIBAgIUdGVzdC1kdW1teS1jYS1jZXJ0aWZpY2F0ZTAeFw0yNjAx',
  'MDEwMDAwMDBaFw0zNjAxMDEwMDAwMDBaMBcxFTATBgNVBAMMDHd3dy50ZXN0LmNv',
  '-----END CERTIFICATE-----',
].join('\n');

const DUMMY_CA_BASE64 = Buffer.from(DUMMY_PEM_CERT, 'utf-8').toString('base64');

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

  it('5. Konfigurasi database lokal (XAMPP) tetap kompatibel tanpa SSL saat DB_SSL=false', () => {
    const parsed = parseEnv({
      NODE_ENV: 'development',
      PORT: '3000',
      DB_HOST: 'localhost',
      DB_PORT: '3306',
      DB_USER: 'root',
      DB_PASSWORD: '',
      DB_NAME: 'mynotes_db',
      DB_SSL: 'false',
      DB_SSL_CA_BASE64: '',
      JWT_SECRET: 'test_local_jwt_secret',
    });

    expect(parsed.success).toBe(true);
    if (!parsed.success) return;

    expect(parsed.data.DB_SSL).toBe(false);
    const sslOptions = buildDatabaseSslOptions(parsed.data);
    expect(sslOptions).toBeUndefined();

    const poolOptions = buildDatabasePoolOptions(parsed.data);
    expect(poolOptions.ssl).toBeUndefined();
    expect(poolOptions.host).toBe('localhost');
    expect(poolOptions.database).toBe('mynotes_db');
  });

  it('6. Konfigurasi SSL/TLS men-decode DB_SSL_CA_BASE64 dan mengaktifkan rejectUnauthorized: true saat DB_SSL=true', () => {
    const parsed = parseEnv({
      NODE_ENV: 'production',
      PORT: '3000',
      DB_HOST: 'mysql-example.aivencloud.com',
      DB_PORT: '17374',
      DB_USER: 'avnadmin',
      DB_PASSWORD: 'placeholder_password_for_unit_test',
      DB_NAME: 'defaultdb',
      DB_SSL: 'true',
      DB_SSL_CA_BASE64: DUMMY_CA_BASE64,
      JWT_SECRET: 'test_production_jwt_secret',
    });

    expect(parsed.success).toBe(true);
    if (!parsed.success) return;

    expect(parsed.data.DB_SSL).toBe(true);
    const sslOptions = buildDatabaseSslOptions(parsed.data);
    expect(sslOptions).toBeDefined();
    expect(sslOptions).toEqual({
      ca: DUMMY_PEM_CERT,
      rejectUnauthorized: true,
    });

    const poolOptions = buildDatabasePoolOptions(parsed.data);
    expect(poolOptions.ssl).toEqual({
      ca: DUMMY_PEM_CERT,
      rejectUnauthorized: true,
    });
  });

  it('7. Validasi menolak konfigurasi DB_SSL=true jika DB_SSL_CA_BASE64 kosong atau tidak valid', () => {
    const missingCa = parseEnv({
      NODE_ENV: 'production',
      DB_HOST: 'mysql-example.aivencloud.com',
      DB_PORT: '17374',
      DB_USER: 'avnadmin',
      DB_PASSWORD: 'placeholder_password',
      DB_NAME: 'defaultdb',
      DB_SSL: 'true',
      DB_SSL_CA_BASE64: '',
      JWT_SECRET: 'test_production_jwt_secret',
    });

    expect(missingCa.success).toBe(false);
    if (!missingCa.success) {
      const paths = missingCa.error.issues.map((i) => i.path.join('.'));
      expect(paths).toContain('DB_SSL_CA_BASE64');
    }

    const invalidCa = parseEnv({
      NODE_ENV: 'production',
      DB_HOST: 'mysql-example.aivencloud.com',
      DB_PORT: '17374',
      DB_USER: 'avnadmin',
      DB_PASSWORD: 'placeholder_password',
      DB_NAME: 'defaultdb',
      DB_SSL: 'true',
      DB_SSL_CA_BASE64: Buffer.from('not-a-valid-pem-certificate').toString('base64'),
      JWT_SECRET: 'test_production_jwt_secret',
    });

    expect(invalidCa.success).toBe(false);

    expect(() =>
      buildDatabaseSslOptions({
        NODE_ENV: 'production',
        DB_SSL: true,
        DB_SSL_CA_BASE64: '',
      })
    ).toThrow(/DB_SSL_CA_BASE64/i);
  });
});

