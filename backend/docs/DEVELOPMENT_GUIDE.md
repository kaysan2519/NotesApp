# Panduan Pengembangan & Modifikasi — MyNotes Backend

Panduan ini dibuat agar developer (termasuk pemula) dapat dengan cepat menemukan file yang tepat ketika ingin mengubah perilaku aplikasi atau menambahkan fitur baru.

---

## Peta Cepat Modifikasi ("Buka File Apa?")

| Apa yang Ingin Anda Ubah? | File yang Harus Dibuka |
|---|---|
| Mengubah koneksi / pool database MySQL | `backend/src/config/database.ts` |
| Mengubah atau menambah variabel `.env` | `backend/src/config/env.ts` & `backend/.env` |
| Menambah atau mengubah pilihan warna catatan | `backend/src/config/note-colors.ts` |
| Mengubah proses Register atau Login | `backend/src/modules/auth/auth.service.ts` |
| Mengubah aturan validasi Register / Login | `backend/src/modules/auth/auth.validation.ts` |
| Mengubah query SQL Notes (search/filter/urutan) | `backend/src/modules/notes/notes.repository.ts` |
| Mengubah aturan bisnis Notes | `backend/src/modules/notes/notes.service.ts` |
| Mengubah aturan validasi input Notes | `backend/src/modules/notes/notes.validation.ts` |
| Mengubah format standar JSON response API | `backend/src/utils/response.util.ts` |
| Mengubah konfigurasi atau payload JWT | `backend/src/utils/jwt.util.ts` |
| Mengubah keamanan middleware (Auth, Rate Limit, Error) | `backend/src/middleware/` |
| Mengubah skema tabel database | `backend/database/migrations/` |

---

## 1. Cara Menambah Endpoint Baru

Misalkan Anda ingin menambahkan endpoint `DELETE /api/notes/clear-all` untuk menghapus semua catatan milik pengguna yang sedang login:

1. **Tambahkan fungsi query di Repository (`src/modules/notes/notes.repository.ts`):**
   ```ts
   public async deleteAllByUser(userId: number): Promise<number> {
     const [result] = await pool.execute<ResultSetHeader>(
       'DELETE FROM notes WHERE user_id = ?',
       [userId]
     );
     return result.affectedRows;
   }
   ```
2. **Tambahkan fungsi bisnis di Service (`src/modules/notes/notes.service.ts`):**
   ```ts
   public async clearAllNotes(userId: number): Promise<number> {
     return notesRepository.deleteAllByUser(userId);
   }
   ```
3. **Tambahkan handler di Controller (`src/modules/notes/notes.controller.ts`):**
   ```ts
   public async clearAllNotes(req: Request, res: Response, next: NextFunction): Promise<void> {
     try {
       const userId = this.getUserId(req);
       const deletedCount = await notesService.clearAllNotes(userId);
       sendSuccess(res, 'All notes deleted', { deletedCount }, 200);
     } catch (error) {
       next(error);
     }
   }
   ```
4. **Daftarkan route di `src/modules/notes/notes.routes.ts`:**
   ```ts
   router.delete('/clear-all', (req, res, next) =>
     notesController.clearAllNotes(req, res, next)
   );
   ```

---

## 2. Cara Menambah atau Mengubah Pilihan Warna Catatan

Daftar warna catatan dikelola secara terpusat di satu file saja:
1. Buka `backend/src/config/note-colors.ts`.
2. Tambahkan properti warna baru di objek `NOTE_COLORS`:
   ```ts
   export const NOTE_COLORS = {
     MINT_GREEN: '#A5F3AD',
     LAVENDER: '#D8A7F5',
     YELLOW: '#F6DB59',
     PINK: '#F2A3A6',
     TURQUOISE: '#70DDC7',
     BLUE: '#83BCEB',
     GRAY: '#D9D9D9',
     WHITE: '#FFFFFF',
     PEACH: '#FFD8BE', // <-- Warna baru
   } as const;
   ```
3. Seluruh validasi pada `createNoteSchema`, `updateNoteSchema`, dan `notesQuerySchema` akan otomatis mengenali warna baru tersebut tanpa perlu mengubah file lain.

---

## 3. Cara Mengubah Validasi Input

Validasi menggunakan **Zod**:
- Untuk validasi autentikasi, buka `backend/src/modules/auth/auth.validation.ts`.
  Contoh: jika ingin mengubah panjang minimal password dari 6 menjadi 8 karakter, ubah `.min(6, ...)` menjadi `.min(8, 'Password minimal 8 karakter')`.
- Untuk validasi catatan, buka `backend/src/modules/notes/notes.validation.ts`.
  Contoh: jika ingin memperbesar batas panjang judul catatan dari 150 menjadi 200 karakter, ubah `.max(150, ...)` pada `createNoteSchema` dan `updateNoteSchema` (serta sesuaikan kolom database melalui migrasi baru).

---

## 4. Cara Mengubah Database Schema atau Menambah Tabel Baru

Jangan mengedit file migrasi yang sudah pernah dijalankan. Buatlah file migrasi baru dengan nomor urut berikutnya di `backend/database/migrations/`:

1. Buat file baru, misalnya `backend/database/migrations/003_add_category_to_notes.sql`:
   ```sql
   ALTER TABLE notes
   ADD COLUMN category VARCHAR(50) NULL DEFAULT NULL AFTER color;
   ```
2. Atau untuk menambah tabel baru, buat `003_create_tags_table.sql`:
   ```sql
   CREATE TABLE IF NOT EXISTS tags (
     id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     user_id BIGINT UNSIGNED NOT NULL,
     name VARCHAR(50) NOT NULL,
     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
     CONSTRAINT fk_tags_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
   ```
3. Jalankan perintah:
   ```bash
   npm run migrate
   ```
   Migration runner (`src/database/migrate.ts`) hanya akan mengeksekusi file `.sql` baru yang belum tercatat di tabel `schema_migrations`.

---

## 5. Cara Mengubah Autentikasi & JWT

- **Mengubah masa berlaku token:** Ubah nilai `JWT_EXPIRES_IN` di dalam file `backend/.env` (contoh: `7d` untuk 7 hari, atau `12h` untuk 12 jam).
- **Mengubah isi payload JWT:** Buka `backend/src/types/express.d.ts` dan `backend/src/utils/jwt.util.ts`.
- **Mengubah cara pemeriksaan header Authorization:** Buka `backend/src/middleware/auth.middleware.ts`.

---

## 6. Cara Mengubah Format Standar Response API

Seluruh response JSON dikirim melalui fungsi `sendSuccess()` dan `sendError()` di dalam `backend/src/utils/response.util.ts`.
Jika Anda ingin menambahkan field baru (misalnya `timestamp` pada setiap response API), cukup ubah fungsi `sendSuccess` dan `sendError` di file tersebut.

---

## 7. Cara Menjalankan Testing

Pengujian integrasi menggunakan **Vitest** dan **Supertest** pada database terpisah (`mynotes_test_db`) sehingga data asli Anda di `mynotes_db` tetap aman:

```bash
# Menjalankan seluruh test satu kali
npm test

# Menjalankan test dalam mode watch (otomatis jalan saat kode berubah)
npm run test:watch

# Memeriksa tipe TypeScript
npm run typecheck
```
