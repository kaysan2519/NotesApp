# Dokumentasi Struktur Project — MyNotes Backend

Dokumen ini menjelaskan fungsi setiap direktori dan file pada backend **MyNotes** agar mudah dipahami, dipelajari, dan dimodifikasi.

---

## 1. Peta Direktori Backend

```text
backend/
├── database/
│   ├── migrations/
│   │   ├── 001_create_users_table.sql   # Skema SQL tabel users
│   │   └── 002_create_notes_table.sql   # Skema SQL tabel notes + foreign key & index
│   └── seeds/                           # Direktori data seeder opsional
│
├── docs/
│   ├── API_DOCUMENTATION.md             # Dokumentasi lengkap endpoint REST API
│   ├── PROJECT_STRUCTURE.md             # Penjelasan fungsi folder & file (dokumen ini)
│   ├── DEVELOPMENT_GUIDE.md             # Panduan modifikasi dan pengembangan fitur
│   └── FLUTTER_INTEGRATION_GUIDE.md     # Panduan integrasi untuk aplikasi Flutter
│
├── src/
│   ├── config/
│   │   ├── env.ts                       # Memuat & memvalidasi .env menggunakan Zod
│   │   ├── database.ts                  # Konfigurasi koneksi pool MySQL
│   │   └── note-colors.ts               # Konfigurasi terpusat daftar warna catatan
│   │
│   ├── database/
│   │   └── migrate.ts                   # Script untuk menjalankan migrasi SQL secara aman
│   │
│   ├── middleware/
│   │   ├── auth.middleware.ts           # Validasi Bearer Token JWT
│   │   ├── validate.middleware.ts       # Validasi input request menggunakan skema Zod
│   │   ├── rate-limit.middleware.ts     # Pembatasan laju request (proteksi brute-force)
│   │   ├── not-found.middleware.ts      # Handler untuk route yang tidak ditemukan (404)
│   │   └── error.middleware.ts          # Handler terpusat untuk semua jenis error
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.ts           # Definisi endpoint /api/auth/*
│   │   │   ├── auth.controller.ts       # Penerima HTTP request & pengirim response auth
│   │   │   ├── auth.service.ts          # Logika bisnis register, login, & profil user
│   │   │   ├── auth.repository.ts       # Query SQL tabel users
│   │   │   ├── auth.validation.ts       # Skema validasi Zod untuk register & login
│   │   │   └── auth.types.ts            # Tipe data TypeScript modul auth
│   │   │
│   │   └── notes/
│   │       ├── notes.routes.ts          # Definisi endpoint /api/notes/*
│   │       ├── notes.controller.ts      # Penerima HTTP request & pengirim response notes
│   │       ├── notes.service.ts         # Logika bisnis CRUD notes & pemeriksaan kepemilikan
│   │       ├── notes.repository.ts      # Query SQL tabel notes (search, filter, CRUD)
│   │       ├── notes.validation.ts      # Skema validasi Zod untuk operasi notes
│   │       └── notes.types.ts           # Tipe data TypeScript modul notes
│   │
│   ├── types/
│   │   └── express.d.ts                 # Deklarasi properti req.user pada Express Request
│   │
│   ├── utils/
│   │   ├── password.util.ts             # Fungsi hashPassword & verifyPassword (bcrypt)
│   │   ├── jwt.util.ts                  # Fungsi generateToken & verifyToken (JWT)
│   │   └── response.util.ts             # Fungsi sendSuccess, sendError, & class AppError
│   │
│   ├── app.ts                           # Perakitan middleware global & routes Express
│   └── server.ts                        # Entry point server HTTP & graceful shutdown
│
├── tests/
│   ├── auth.test.ts                     # Integration test untuk autentikasi & JWT
│   ├── notes.test.ts                    # Integration test untuk CRUD notes & kepemilikan
│   └── database.test.ts                 # Integration test untuk koneksi & constraint DB
│
├── .env.example                         # Contoh konfigurasi environment
├── package.json                         # Daftar dependencies dan npm scripts
├── tsconfig.json                        # Konfigurasi kompilator TypeScript
└── vitest.config.ts                     # Konfigurasi test runner Vitest
```

---

## 2. Penjelasan Detail Setiap Lapisan (*Separation of Concerns*)

### A. Lapisan Konfigurasi (`src/config/`)
1. **`env.ts`**
   Membaca file `.env` dan memvalidasi setiap variabel menggunakan `zod`. Jika ada konfigurasi penting seperti `JWT_SECRET` atau `DB_HOST` yang belum diisi, aplikasi langsung memberikan pesan error yang jelas saat dinyalakan.
2. **`database.ts`**
   Membuat objek `pool` (`mysql2/promise`) untuk mengelola koneksi ke database MySQL secara efisien, menyediakan fungsi `ensureDatabaseExists()`, `testDatabaseConnection()`, dan `closeDatabasePool()`.
3. **`note-colors.ts`**
   Menyimpan konstanta `NOTE_COLORS`, `ALLOWED_NOTE_COLORS`, dan `DEFAULT_NOTE_COLOR` (`#A5F3AD`). Seluruh validasi warna mengacu ke satu file ini.

### B. Lapisan Utilitas (`src/utils/`)
1. **`response.util.ts`**
   Berisi fungsi `sendSuccess()` dan `sendError()` agar seluruh endpoint menghasilkan struktur JSON `{ success, message, data }` yang seragam, serta class `AppError` untuk melempar error HTTP beserta kode statusnya.
2. **`password.util.ts`**
   Membungkus library `bcrypt` menjadi fungsi `hashPassword()` dan `verifyPassword()`.
3. **`jwt.util.ts`**
   Membungkus library `jsonwebtoken` menjadi fungsi `generateToken()` dan `verifyToken()`.

### C. Lapisan Middleware (`src/middleware/`)
1. **`auth.middleware.ts`**
   Mengekstrak token dari header `Authorization: Bearer <token>`, memverifikasi keaslian dan masa berlaku token melalui `verifyToken()`, lalu menyimpan data pengguna ke `req.user`.
2. **`validate.middleware.ts`**
   Memvalidasi `req.body`, `req.query`, atau `req.params` terhadap skema Zod sebelum request masuk ke controller.
3. **`rate-limit.middleware.ts`**
   Membatasi jumlah percobaan request (khususnya `loginRateLimiter` pada endpoint login) untuk mencegah serangan *brute-force*.
4. **`not-found.middleware.ts`**
   Menangani request ke URL yang tidak terdaftar dengan status `404 Not Found`.
5. **`error.middleware.ts`**
   Menangkap semua error dari seluruh lapisan aplikasi (`ZodError`, `AppError`, error JSON rusak, maupun error database MySQL) dan mengubahnya menjadi response JSON yang aman.

### D. Lapisan Modul Fitur (`src/modules/auth/` & `src/modules/notes/`)
Setiap modul mengikuti alur 4 tingkat yang konsisten:
1. **`*.routes.ts` (Routes):** Menentukan URL endpoint, memasang middleware (`authMiddleware`, `validate`), dan meneruskan request ke controller.
2. **`*.controller.ts` (Controller):** Mengambil data dari `req` (`req.body`, `req.params`, `req.query`, `req.user`), memanggil `service`, dan mengirimkan HTTP response menggunakan `sendSuccess()`.
3. **`*.service.ts` (Service):** Menjalankan aturan bisnis (misalnya memeriksa apakah email sudah dipakai saat registrasi, atau memastikan catatan yang diakses benar-benar ada dan dimiliki oleh user tersebut).
4. **`*.repository.ts` (Repository):** Menjalankan *parameterized SQL queries* (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) ke MySQL menggunakan `pool.execute()`. Tidak ada query SQL di luar file repository.
