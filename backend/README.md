# MyNotes Backend — REST API

Direktori ini berisi source code **Backend REST API** untuk aplikasi **MyNotes** yang dibangun menggunakan **Node.js**, **Express.js**, **TypeScript (Strict Mode)**, dan **MySQL**.

## Struktur Direktori Backend

- `src/config/` — Konfigurasi environment variables dan koneksi MySQL connection pool.
- `src/modules/` — Modul domain bisnis (`auth` dan `notes`) dengan pemisahan *routes*, *controller*, *service*, *repository*, *validation*, dan *types*.
- `src/middleware/` — Middleware autentikasi JWT, validasi Zod, penangan *not found*, dan penangan error terpusat.
- `src/utils/` — Fungsi utilitas untuk hashing password (`bcrypt`), manajemen token (`JWT`), dan format standar response JSON.
- `src/types/` — Augmentasi tipe TypeScript (`express.d.ts`).
- `database/migrations/` — Skema SQL untuk pembuatan tabel `users` dan `notes`.
- `docs/` — Dokumentasi lengkap endpoint API, struktur project, panduan pengembangan, dan panduan integrasi Flutter.
- `tests/` — Pengujian integrasi menggunakan Vitest dan Supertest.
