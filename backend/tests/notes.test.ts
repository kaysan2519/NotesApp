import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import request from 'supertest';
import app from '../src/app';
import { pool } from '../src/config/database';
import { env } from '../src/config/env';
import { runMigrations } from '../src/database/migrate';

describe('Notes Management CRUD & Ownership Integration Tests (/api/notes)', () => {
  let tokenUserA = '';
  let tokenUserB = '';

  beforeAll(async () => {
    if (env.DB_NAME !== 'mynotes_test_db') {
      throw new Error(`Testing wajib menggunakan mynotes_test_db, bukan ${env.DB_NAME}`);
    }
    await runMigrations(pool, env.DB_NAME);
  });

  beforeEach(async () => {
    await pool.execute('DELETE FROM notes');
    await pool.execute('DELETE FROM users');

    const regA = await request(app).post('/api/auth/register').send({
      username: 'user_a',
      email: 'usera@example.com',
      password: 'password123',
    });
    tokenUserA = regA.body.data.token as string;

    const regB = await request(app).post('/api/auth/register').send({
      username: 'user_b',
      email: 'userb@example.com',
      password: 'password123',
    });
    tokenUserB = regB.body.data.token as string;
  });

  it('1. Create note berhasil (201 Created)', async () => {
    const res = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        title: 'Business Team Meeting',
        content: 'Persiapan meeting bersama tim.',
        color: '#A5F3AD',
        is_pinned: false,
        is_private: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({
      title: 'Business Team Meeting',
      content: 'Persiapan meeting bersama tim.',
      color: '#A5F3AD',
      is_pinned: false,
      is_private: true,
    });
  });

  it('2. Read semua notes milik pengguna berhasil dan terurut pinned terlebih dahulu (200 OK)', async () => {
    await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Regular Note', content: 'First regular note', is_pinned: false });

    await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Pinned Important Note', content: 'Top priority', is_pinned: true });

    const res = await request(app)
      .get('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBe(2);
    expect(res.body.data[0].title).toBe('Pinned Important Note');
    expect(res.body.data[0].is_pinned).toBe(true);
  });

  it('3. Read detail note berhasil bagi pemilik (200 OK)', async () => {
    const created = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Detail Note', content: 'Detailed content' });

    const noteId = created.body.data.id as number;

    const detailRes = await request(app)
      .get(`/api/notes/${noteId}`)
      .set('Authorization', `Bearer ${tokenUserA}`);

    expect(detailRes.status).toBe(200);
    expect(detailRes.body.success).toBe(true);
    expect(detailRes.body.data.id).toBe(noteId);
    expect(detailRes.body.data.title).toBe('Detail Note');
  });

  it('4. Update note (judul, isi, warna, pin, privacy) berhasil (200 OK)', async () => {
    const created = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Old Title', content: 'Old Content', color: '#A5F3AD' });

    const noteId = created.body.data.id as number;

    const updateRes = await request(app)
      .put(`/api/notes/${noteId}`)
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        title: 'New Title',
        content: 'New Content',
        color: '#D8A7F5',
        is_pinned: true,
        is_private: false,
      });

    expect(updateRes.status).toBe(200);
    expect(updateRes.body.data).toMatchObject({
      id: noteId,
      title: 'New Title',
      content: 'New Content',
      color: '#D8A7F5',
      is_pinned: true,
      is_private: false,
    });
  });

  it('5. Delete note berhasil dan benar-benar terhapus dari database (200 OK)', async () => {
    const created = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'To Be Deleted', content: 'Temp' });

    const noteId = created.body.data.id as number;

    const delRes = await request(app)
      .delete(`/api/notes/${noteId}`)
      .set('Authorization', `Bearer ${tokenUserA}`);

    expect(delRes.status).toBe(200);
    expect(delRes.body.success).toBe(true);

    const checkRes = await request(app)
      .get(`/api/notes/${noteId}`)
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(checkRes.status).toBe(404);
  });

  it('6. Search berdasarkan title maupun content berhasil', async () => {
    await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Project Architecture', content: 'Use Express and MySQL' });

    await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Shopping List', content: 'Buy coffee beans' });

    const searchByTitle = await request(app)
      .get('/api/notes?search=Architecture')
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(searchByTitle.status).toBe(200);
    expect(searchByTitle.body.data.length).toBe(1);
    expect(searchByTitle.body.data[0].title).toBe('Project Architecture');

    const searchByContent = await request(app)
      .get('/api/notes?search=coffee')
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(searchByContent.status).toBe(200);
    expect(searchByContent.body.data.length).toBe(1);
    expect(searchByContent.body.data[0].title).toBe('Shopping List');
  });

  it('7. Filter pinned serta endpoint PATCH /pin dan PATCH /privacy berhasil', async () => {
    const created = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Toggle Note', is_pinned: false, is_private: true });

    const noteId = created.body.data.id as number;

    const pinRes = await request(app)
      .patch(`/api/notes/${noteId}/pin`)
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ is_pinned: true });
    expect(pinRes.status).toBe(200);
    expect(pinRes.body.data.is_pinned).toBe(true);

    const privRes = await request(app)
      .patch(`/api/notes/${noteId}/privacy`)
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ is_private: false });
    expect(privRes.status).toBe(200);
    expect(privRes.body.data.is_private).toBe(false);

    const pinnedList = await request(app)
      .get('/api/notes?is_pinned=true')
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(pinnedList.status).toBe(200);
    expect(pinnedList.body.data.length).toBe(1);
    expect(pinnedList.body.data[0].id).toBe(noteId);
  });

  it('8. Update warna berhasil untuk warna valid dan menolak warna tidak valid', async () => {
    const created = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Color Note', color: '#A5F3AD' });

    const noteId = created.body.data.id as number;

    const validColorRes = await request(app)
      .put(`/api/notes/${noteId}`)
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ color: '#F6DB59' });
    expect(validColorRes.status).toBe(200);
    expect(validColorRes.body.data.color).toBe('#F6DB59');

    const invalidColorRes = await request(app)
      .put(`/api/notes/${noteId}`)
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ color: '#123456' });
    expect(invalidColorRes.status).toBe(400);
    expect(invalidColorRes.body.success).toBe(false);
  });

  it('9. Akses endpoint Notes tanpa token atau dengan token invalid ditolak (401 Unauthorized)', async () => {
    const noTokenRes = await request(app).get('/api/notes');
    expect(noTokenRes.status).toBe(401);

    const badTokenRes = await request(app)
      .post('/api/notes')
      .set('Authorization', 'Bearer invalid_token')
      .send({ title: 'Unauthorized Note' });
    expect(badTokenRes.status).toBe(401);
  });

  it('10. Pengguna A tidak bisa membaca, mengedit, atau menghapus notes milik Pengguna B', async () => {
    // Pengguna B membuat catatan
    const createdByB = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserB}`)
      .send({ title: 'Rahasia User B', content: 'Hanya milik B' });

    const noteBId = createdByB.body.data.id as number;

    // Pengguna A mencoba membaca daftar catatan -> tidak boleh ada catatan milik B
    const listA = await request(app)
      .get('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(listA.body.data.length).toBe(0);

    // Pengguna A mencoba membaca detail catatan B -> ditolak 404 tanpa bocor data
    const readByA = await request(app)
      .get(`/api/notes/${noteBId}`)
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(readByA.status).toBe(404);
    expect(readByA.body.data).toBeNull();

    // Pengguna A mencoba mengedit catatan B -> ditolak 404
    const editByA = await request(app)
      .put(`/api/notes/${noteBId}`)
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: 'Diubah oleh A' });
    expect(editByA.status).toBe(404);

    // Pengguna A mencoba menghapus catatan B -> ditolak 404
    const deleteByA = await request(app)
      .delete(`/api/notes/${noteBId}`)
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(deleteByA.status).toBe(404);

    // Pastikan catatan B masih utuh bagi B
    const verifyByB = await request(app)
      .get(`/api/notes/${noteBId}`)
      .set('Authorization', `Bearer ${tokenUserB}`);
    expect(verifyByB.status).toBe(200);
    expect(verifyByB.body.data.title).toBe('Rahasia User B');
  });

  it('11. Input tidak valid pada Notes ditolak dengan 400 Bad Request', async () => {
    const emptyTitleRes = await request(app)
      .post('/api/notes')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({ title: '   ', content: 'No title' });
    expect(emptyTitleRes.status).toBe(400);

    const invalidIdParamRes = await request(app)
      .get('/api/notes/not-a-number')
      .set('Authorization', `Bearer ${tokenUserA}`);
    expect(invalidIdParamRes.status).toBe(400);
  });
});
