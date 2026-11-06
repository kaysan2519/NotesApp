import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import app from '../src/app';
import { pool } from '../src/config/database';
import { env } from '../src/config/env';
import { runMigrations } from '../src/database/migrate';
import { UserRow } from '../src/modules/auth/auth.types';

describe('Authentication Integration Tests (/api/auth)', () => {
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

  it('1. Register berhasil dengan data valid (201 Created)', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'jessica@example.com',
      password: 'password123',
    });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user).toMatchObject({
      username: 'jessica',
      email: 'jessica@example.com',
    });
    expect(res.body.data.user.password).toBeUndefined();
    expect(typeof res.body.data.token).toBe('string');
  });

  it('2. Register dengan email duplikat ditolak (409 Conflict)', async () => {
    await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'jessica@example.com',
      password: 'password123',
    });

    const dupRes = await request(app).post('/api/auth/register').send({
      username: 'jessica_two',
      email: 'JESSICA@example.com',
      password: 'password456',
    });

    expect(dupRes.status).toBe(409);
    expect(dupRes.body.success).toBe(false);
    expect(dupRes.body.data).toBeNull();
  });

  it('3. Register dengan input tidak valid ditolak (400 Bad Request)', async () => {
    const badEmailRes = await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'bukan-email',
      password: 'password123',
    });
    expect(badEmailRes.status).toBe(400);
    expect(badEmailRes.body.success).toBe(false);

    const shortPassRes = await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'valid@example.com',
      password: '123',
    });
    expect(shortPassRes.status).toBe(400);
    expect(shortPassRes.body.success).toBe(false);
  });

  it('4. Password tersimpan dalam bentuk bcrypt hash di database (bukan plaintext)', async () => {
    const plainPassword = 'mySecretPassword123';
    await request(app).post('/api/auth/register').send({
      username: 'secureuser',
      email: 'secure@example.com',
      password: plainPassword,
    });

    const [rows] = await pool.execute<UserRow[]>(
      'SELECT password FROM users WHERE email = ?',
      ['secure@example.com']
    );

    expect(rows.length).toBe(1);
    const storedHash = rows[0]!.password;
    expect(storedHash).not.toBe(plainPassword);
    expect(storedHash.startsWith('$2b$')).toBe(true);
  });

  it('5. Login berhasil dengan email dan password yang benar (200 OK)', async () => {
    await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'jessica@example.com',
      password: 'password123',
    });

    const loginRes = await request(app).post('/api/auth/login').send({
      email: 'jessica@example.com',
      password: 'password123',
    });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.success).toBe(true);
    expect(loginRes.body.message).toBe('Login successful');
    expect(loginRes.body.data.user).toMatchObject({
      username: 'jessica',
      email: 'jessica@example.com',
    });
    expect(loginRes.body.data.user.password).toBeUndefined();
    expect(typeof loginRes.body.data.token).toBe('string');
  });

  it('6. Login dengan password salah ditolak (401 Unauthorized)', async () => {
    await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'jessica@example.com',
      password: 'password123',
    });

    const badPassRes = await request(app).post('/api/auth/login').send({
      email: 'jessica@example.com',
      password: 'wrongpassword',
    });

    expect(badPassRes.status).toBe(401);
    expect(badPassRes.body.success).toBe(false);
    expect(badPassRes.body.data).toBeNull();
  });

  it('7. Login dengan email tidak ditemukan ditolak (401 Unauthorized)', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'unknown@example.com',
      password: 'password123',
    });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.data).toBeNull();
  });

  it('8. JWT valid diterima dan endpoint GET /api/auth/me berhasil (200 OK)', async () => {
    const regRes = await request(app).post('/api/auth/register').send({
      username: 'jessica',
      email: 'jessica@example.com',
      password: 'password123',
    });

    const token = regRes.body.data.token as string;

    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.success).toBe(true);
    expect(meRes.body.data.user).toMatchObject({
      username: 'jessica',
      email: 'jessica@example.com',
    });
    expect(meRes.body.data.user.password).toBeUndefined();
  });

  it('9. JWT expired ditolak oleh authMiddleware (401 Unauthorized)', async () => {
    const expiredToken = jwt.sign(
      { id: 1, email: 'jessica@example.com', username: 'jessica' },
      env.JWT_SECRET,
      { expiresIn: -10 }
    );

    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${expiredToken}`);

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('10. JWT invalid atau tanda tangan palsu ditolak (401 Unauthorized)', async () => {
    const forgedToken = jwt.sign(
      { id: 1, email: 'jessica@example.com', username: 'jessica' },
      'wrong_secret_key'
    );

    const res1 = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${forgedToken}`);
    expect(res1.status).toBe(401);

    const res2 = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'InvalidHeaderFormat');
    expect(res2.status).toBe(401);

    const res3 = await request(app).get('/api/auth/me');
    expect(res3.status).toBe(401);
  });
});
