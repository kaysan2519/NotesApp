# MyNotes — Personal Notes Management Application

**MyNotes** adalah aplikasi pencatatan pribadi (*Personal Notes Management Application*) yang dirancang untuk membuat, menyimpan, mengelola, dan mengatur catatan pribadi pengguna secara aman, cepat, dan terstruktur.

Project ini menggunakan arsitektur monorepo terpisah antara **Backend REST API** (`./backend`) dan **Frontend Mobile Application** (`./frontend`).

---

## Daftar Isi

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Prerequisites](#3-prerequisites)
4. [Arsitektur Repository](#4-arsitektur-repository)
5. [Instalasi & Setup Backend](#5-instalasi--setup-backend)
6. [Setup Database & Migrasi](#6-setup-database--migrasi)
7. [Perintah Development, Build, & Testing](#7-perintah-development-build--testing)
8. [Ringkasan Endpoint REST API](#8-ringkasan-endpoint-rest-api)
9. [Dokumentasi Teknis Lengkap](#9-dokumentasi-teknis-lengkap)

---

## 1. Project Overview

Pengguna aplikasi **MyNotes** dapat:
1. Membuat akun pengguna baru (*Register*).
2. Login menggunakan email dan password berbasis JWT (*JSON Web Token*).
3. Melihat seluruh catatan miliknya yang diurutkan otomatis (*pinned* terlebih dahulu, lalu berdasarkan waktu perubahan terbaru).
4. Membuat catatan baru dengan pilihan warna kartu.
5. Membaca detail catatan.
6. Mengedit judul, isi, warna, maupun pengaturan catatan.
7. Menghapus catatan secara permanen dari database MySQL.
8. Mengatur warna kartu catatan dari 8 palet warna pastel resmi.
9. Menandai catatan penting menggunakan fitur *Pin*.
10. Mengatur status privasi catatan (*Private Setting*).
11. Mencari catatan berdasarkan kata kunci pada judul (*title*) maupun isi (*content*).
12. Logout dari aplikasi.

Seluruh data disimpan secara permanen di database **MySQL** (`mynotes_db`) dengan proteksi kepemilikan data (*ownership authorization*) sehingga Pengguna A tidak dapat membaca, mengubah, atau menghapus catatan milik Pengguna B.

---

## 2. Technology Stack

### Backend (`./backend`)
- **Runtime:** Node.js LTS (v20+ / v22+)
- **Framework:** Express.js 4
- **Programming Language:** TypeScript 5 (`strict: true`)
- **Database:** MySQL / MariaDB (`mysql2/promise` connection pool)
- **Authentication:** JSON Web Token (`jsonwebtoken`)
- **Password Hashing:** `bcrypt`
- **Validation:** `zod`
- **Security:** `helmet`, `cors`, `express-rate-limit`
- **Logging:** `morgan`
- **Testing:** `vitest` & `supertest`

### Frontend (`./frontend` — *Tahap Berikutnya*)
- **Framework:** Flutter
- **Language:** Dart

---

## 3. Prerequisites

Pastikan perangkat Anda telah terinstal:
- **Node.js** v18 LTS atau lebih baru (direkomendasikan v20 / v22 LTS)
- **npm** v9 atau lebih baru
- **MySQL Server** 8.0+ atau **MariaDB** 10.4+ (misalnya melalui XAMPP, Laragon, atau MySQL Installer)
- **Git**

---

## 4. Arsitektur Repository

```text
MyNotes/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── env.ts                # Validasi variabel environment (Zod)
│   │   │   ├── database.ts           # MySQL connection pool (mysql2/promise)
│   │   │   └── note-colors.ts        # Konfigurasi terpusat palet warna catatan
│   │   ├── modules/
│   │   │   ├── auth/                 # Modul autentikasi (routes, controller, service, repo, validation, types)
│   │   │   └── notes/                # Modul CRUD catatan (routes, controller, service, repo, validation, types)
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts    # Proteksi Bearer JWT
│   │   │   ├── validate.middleware.ts# Validasi request body/query/params (Zod)
│   │   │   ├── rate-limit.middleware.ts # Pembatasan request (anti brute-force)
│   │   │   ├── not-found.middleware.ts  # Penanganan endpoint 404
│   │   │   └── error.middleware.ts   # Centralized error handler
│   │   ├── utils/
│   │   │   ├── password.util.ts      # Hashing & verifikasi password (bcrypt)
│   │   │   ├── jwt.util.ts           # Pembuatan & verifikasi JWT
│   │   │   └── response.util.ts      # Format standar JSON response & AppError
│   │   ├── types/
│   │   │   └── express.d.ts          # Augmentasi tipe Express.Request
│   │   ├── database/
│   │   │   └── migrate.ts            # Migration runner SQL otomatis & aman
│   │   ├── app.ts                    # Konfigurasi aplikasi Express
│   │   └── server.ts                 # Entry point HTTP server & graceful shutdown
│   ├── database/
│   │   ├── migrations/               # File SQL pembuatan tabel users & notes
│   │   └── seeds/                    # Direktori seeder opsional
│   ├── docs/                         # Dokumentasi teknis lengkap
│   ├── tests/                        # Integration tests (auth, notes, database)
│   ├── .env.example                  # Template variabel environment
│   ├── package.json                  # Dependencies & scripts backend
│   ├── tsconfig.json                 # Konfigurasi TypeScript strict mode
│   └── vitest.config.ts              # Konfigurasi pengujian Vitest
├── frontend/
│   └── README.md                     # Placeholder untuk aplikasi Flutter
├── .gitignore
├── README.md
└── LICENSE
```

---

## 5. Instalasi & Setup Backend

1. Masuk ke direktori `backend`:
   ```bash
   cd backend
   ```

2. Instal seluruh dependencies:
   ```bash
   npm install
   ```

3. Salin file `.env.example` menjadi `.env`:
   ```bash
   cp .env.example .env
   ```
   *(Di Windows PowerShell: `Copy-Item .env.example .env`)*

4. Sesuaikan nilai di dalam `backend/.env` dengan konfigurasi MySQL lokal Anda:
   ```env
   NODE_ENV=development
   PORT=3000

   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=
   DB_NAME=mynotes_db

   JWT_SECRET=ganti_dengan_secret_key_rahasia_anda
   JWT_EXPIRES_IN=1d

   BCRYPT_SALT_ROUNDS=12

   CORS_ORIGIN=*
   ```

---

## 6. Setup Database & Migrasi

Pastikan layanan **MySQL / MariaDB** sedang berjalan di komputer Anda, lalu jalankan perintah migrasi berikut dari dalam folder `backend/`:

```bash
npm run migrate
```

Migration runner akan secara otomatis:
1. Membuat database `mynotes_db` apabila belum tersedia (`CREATE DATABASE IF NOT EXISTS`).
2. Membuat tabel pencatat migrasi `schema_migrations`.
3. Menjalankan `001_create_users_table.sql` dan `002_create_notes_table.sql` secara berurutan tanpa menghapus data yang sudah ada.

---

## 7. Perintah Development, Build, & Testing

Jalankan perintah berikut dari dalam direktori `backend/`:

| Perintah | Fungsi |
|---|---|
| `npm run dev` | Menjalankan server development dengan auto-reload (`tsx watch src/server.ts`) |
| `npm run typecheck` | Memeriksa tipe TypeScript secara menyeluruh (`tsc --noEmit`) |
| `npm run build` | Mengompilasi kode TypeScript ke folder `dist/` (`tsc`) |
| `npm start` | Menjalankan hasil build production (`node dist/server.js`) |
| `npm run migrate` | Menjalankan migrasi database MySQL |
| `npm test` | Menjalankan seluruh integration test pada database uji terpisah (`mynotes_test_db`) |

---

## 8. Ringkasan Endpoint REST API

Base URL: `http://localhost:3000/api`

| Method | Endpoint | Auth JWT | Deskripsi |
|---|---|---|---|
| `GET` | `/api/health` | Tidak | Memeriksa status server dan koneksi database |
| `POST` | `/api/auth/register` | Tidak | Registrasi akun pengguna baru |
| `POST` | `/api/auth/login` | Tidak | Login pengguna dan mendapatkan JWT token |
| `GET` | `/api/auth/me` | **Wajib** | Mengambil profil pengguna yang sedang login |
| `POST` | `/api/notes` | **Wajib** | Membuat catatan baru |
| `GET` | `/api/notes` | **Wajib** | Mengambil daftar catatan (mendukung `?search=`, `?is_pinned=`, `?color=`) |
| `GET` | `/api/notes/:id` | **Wajib** | Mengambil detail satu catatan milik pengguna |
| `PUT` | `/api/notes/:id` | **Wajib** | Memperbarui isi/pengaturan catatan |
| `DELETE` | `/api/notes/:id` | **Wajib** | Menghapus catatan secara permanen |
| `PATCH` | `/api/notes/:id/pin` | **Wajib** | Mengubah status *pin* catatan |
| `PATCH` | `/api/notes/:id/privacy` | **Wajib** | Mengubah status privasi (`is_private`) catatan |

---

## 9. Dokumentasi Teknis Lengkap

Dokumentasi mendalam tersedia di dalam folder `backend/docs/`:
- [API_DOCUMENTATION.md](backend/docs/API_DOCUMENTATION.md) — Spesifikasi lengkap seluruh endpoint, contoh request/response JSON, status code, dan panduan pengujian Postman.
- [PROJECT_STRUCTURE.md](backend/docs/PROJECT_STRUCTURE.md) — Penjelasan fungsi setiap folder, file, controller, service, repository, middleware, dan utilitas.
- [DEVELOPMENT_GUIDE.md](backend/docs/DEVELOPMENT_GUIDE.md) — Panduan langkah demi langkah untuk memodifikasi fitur, menambah endpoint, mengubah skema database, dan menjalankan pengujian.
- [FLUTTER_INTEGRATION_GUIDE.md](backend/docs/FLUTTER_INTEGRATION_GUIDE.md) — Panduan lengkap mengintegrasikan aplikasi mobile Flutter dengan backend MyNotes REST API.
