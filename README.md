# MyNotes — Personal Notes Management Application

**MyNotes** adalah aplikasi pencatatan pribadi (*Personal Notes Management Application*) untuk membuat, menyimpan, mengelola, dan mengatur catatan pribadi pengguna secara aman dan terstruktur.

Project ini menggunakan arsitektur monorepo terpisah antara **Backend REST API** dan **Frontend Mobile Application**.

---

## Fitur Utama

1. Registrasi akun pengguna baru.
2. Autentikasi login menggunakan email dan password berbasis JWT.
3. Melihat seluruh daftar catatan milik pengguna yang sedang login.
4. Membuat catatan baru.
5. Membaca detail catatan.
6. Mengubah isi dan pengaturan catatan.
7. Menghapus catatan secara permanen dari database.
8. Mengatur warna kartu catatan (*Note Color*).
9. Menandai catatan penting menggunakan fitur *Pin*.
10. Mengatur status privasi catatan (*Private Setting*).
11. Mencari catatan berdasarkan judul maupun isi (*Search*).
12. Logout dari aplikasi.

---

## Arsitektur Repository

```text
MyNotes/
├── backend/                  # Express.js + TypeScript + MySQL REST API
│   ├── src/
│   │   ├── config/           # Konfigurasi environment & database pool
│   │   ├── modules/          # Modul fitur (auth, notes)
│   │   ├── middleware/       # Middleware autentikasi, validasi, & error
│   │   ├── utils/            # Utilitas reusable (JWT, bcrypt, response)
│   │   ├── types/            # Definisi tipe TypeScript tambahan
│   │   ├── database/         # Helper & runner database internal
│   │   ├── app.ts            # Konfigurasi aplikasi Express
│   │   └── server.ts         # Entry point HTTP server
│   ├── database/
│   │   ├── migrations/       # File migrasi SQL database
│   │   └── seeds/            # Data seeder opsional
│   ├── docs/                 # Dokumentasi teknis API & arsitektur
│   └── tests/                # Pengujian integrasi & unit (Vitest + Supertest)
│
├── frontend/                 # Aplikasi Mobile Flutter (Tahap Berikutnya)
│   └── README.md             # Placeholder dokumentasi frontend
│
├── .gitignore                # Konfigurasi file yang diabaikan Git
├── README.md                 # Dokumentasi utama repository
└── LICENSE                   # Lisensi project (MIT)
```

---

## Technology Stack

### Backend (`./backend`)
- **Runtime:** Node.js LTS
- **Framework:** Express.js
- **Language:** TypeScript (`strict: true`)
- **Database:** MySQL (`mysql2/promise`)
- **Authentication & Security:** JWT (`jsonwebtoken`), `bcrypt`, `helmet`, `cors`, `express-rate-limit`
- **Validation:** `zod`
- **Testing:** `vitest` & `supertest`

### Frontend (`./frontend` — *Direncanakan setelah Backend selesai*)
- **Framework:** Flutter
- **Language:** Dart

---

## Status Pengembangan Saat Ini

- [x] **Phase 0:** Workspace Audit & Git Setup
- [ ] **Phase 1:** Backend Initialization
- [ ] **Phase 2:** MySQL Database & Migrations
- [ ] **Phase 3:** Authentication System (JWT & bcrypt)
- [ ] **Phase 4:** Notes Management CRUD API
- [ ] **Phase 5:** Security & Centralized Error Handling
- [ ] **Phase 6:** Integration Testing & Bug Fixing
- [ ] **Phase 7:** Documentation & Final Backend Audit
- [ ] **Frontend Phase:** Flutter Mobile Application (Menunggu persetujuan setelah Phase 7 selesai)
