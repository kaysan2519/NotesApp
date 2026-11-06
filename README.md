# MyNotes — Personal Notes Management Application

**MyNotes** adalah aplikasi pencatatan pribadi (*Personal Notes Management Application*) full-stack yang terdiri dari **Backend REST API (Express.js + TypeScript + MySQL)** dan **Frontend Mobile Application (Flutter + Dart)**.

---

## Daftar Isi

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Arsitektur Repository](#3-arsitektur-repository)
4. [Panduan Menjalankan Backend & Flutter Bersamaan](#4-panduan-menjalankan-backend--flutter-bersamaan)
5. [Perintah Pengujian & Build](#5-perintah-pengujian--build)
6. [Ringkasan Endpoint REST API](#6-ringkasan-endpoint-rest-api)
7. [Dokumentasi Teknis Lengkap](#7-dokumentasi-teknis-lengkap)

---

## 1. Project Overview

Pengguna aplikasi **MyNotes** dapat:
1. Membuat akun pengguna baru (*Register*).
2. Login menggunakan email dan password berbasis JWT (*JSON Web Token*).
3. Melihat seluruh catatan miliknya yang diurutkan otomatis (*pinned* terlebih dahulu, lalu berdasarkan waktu perubahan terbaru).
4. Membuat catatan baru dengan pilihan warna kartu pastel.
5. Membaca detail catatan.
6. Mengedit judul, isi, warna, maupun pengaturan catatan.
7. Menghapus catatan secara permanen dari database MySQL dengan konfirmasi.
8. Mengatur warna kartu catatan dari 8 palet warna pastel resmi (`#A5F3AD`, `#D8A7F5`, `#F6DB59`, `#F2A3A6`, `#70DDC7`, `#83BCEB`, `#D9D9D9`, `#FFFFFF`).
9. Menandai catatan penting menggunakan fitur *Pin*.
10. Mengatur status privasi catatan (*Private Setting*).
11. Mencari catatan berdasarkan kata kunci pada judul (*title*) maupun isi (*content*).
12. Logout dari aplikasi dengan pembersihan token dari penyimpanan aman.

---

## 2. Technology Stack

### Backend (`./backend`)
- **Runtime & Framework:** Node.js LTS + Express.js
- **Language:** TypeScript (`strict: true`)
- **Database:** MySQL / MariaDB (`mysql2/promise` connection pool)
- **Authentication & Security:** JWT (`jsonwebtoken`), `bcrypt`, `helmet`, `cors`, `express-rate-limit`
- **Validation:** `zod`
- **Testing:** `vitest` & `supertest` (25 integration tests)

### Frontend (`./frontend`)
- **Framework & Language:** Flutter 3 + Dart 3
- **Design System:** Material 3 Custom Design System (Cream pastel background, colorful note cards, dark pill buttons `#202020`)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** GoRouter (`go_router`)
- **HTTP Client:** Dio (`dio`) dengan JWT Bearer Interceptor & 401 handler
- **Secure Storage:** `flutter_secure_storage`
- **Date Formatting:** `intl`

---

## 3. Arsitektur Repository

```text
MyNotes/
├── backend/                  # Express.js + TypeScript + MySQL REST API
│   ├── src/                  # Source code modular (config, modules, middleware, utils, database)
│   ├── database/migrations/  # File migrasi SQL tabel users & notes
│   ├── docs/                 # Dokumentasi API, struktur project, panduan dev & integrasi Flutter
│   └── tests/                # 25 integration tests (Vitest + Supertest)
│
├── frontend/                 # Aplikasi Mobile Flutter
│   ├── lib/                  # Source code modular (config, core, models, services, providers, screens, widgets)
│   ├── test/                 # Widget tests & API service contract tests
│   ├── android/              # Konfigurasi platform Android
│   └── pubspec.yaml          # Konfigurasi dependencies Flutter
│
├── .gitignore
├── README.md
└── LICENSE
```

---

## 4. Panduan Menjalankan Backend & Flutter Bersamaan

### A. Menjalankan Backend (`./backend`)
1. Pastikan service **MySQL / MariaDB** aktif di port `3306`.
2. Buka terminal di folder `backend/`:
   ```bash
   cd backend
   npm install
   cp .env.example .env
   npm run migrate
   npm run dev
   ```
   Server REST API akan aktif di `http://localhost:3000`.

### B. Menjalankan Frontend Flutter (`./frontend`)
1. Buka terminal baru di folder `frontend/`:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
2. **Koneksi Jaringan Otomatis:**
   - Pada **Android Emulator**, aplikasi otomatis terhubung ke `http://10.0.2.2:3000/api`.
   - Pada **Windows / Web / iOS Simulator**, aplikasi otomatis terhubung ke `http://localhost:3000/api`.
   - Pada **Perangkat Fisik (HP Android)**, gunakan `--dart-define=API_BASE_URL=http://<IP_KOMPUTER>:3000/api` atau ubah melalui tombol pengaturan API di pojok kanan atas layar Login.

---

## 5. Perintah Pengujian & Build

### Backend (`./backend`)
- `npm run typecheck` — Pemeriksaan tipe TypeScript (`tsc --noEmit`).
- `npm run build` — Kompilasi production ke `dist/`.
- `npm test` — Menjalankan 25 integration tests pada database uji terpisah (`mynotes_test_db`).

### Frontend (`./frontend`)
- `flutter analyze` — Analisis statis kode Dart/Flutter.
- `flutter test` — Menjalankan seluruh widget test & API service test.
- `flutter build apk --debug` — Membangun file APK Debug Android.

---

## 6. Ringkasan Endpoint REST API

| Method | Endpoint | Auth JWT | Deskripsi |
|---|---|---|---|
| `GET` | `/api/health` | Tidak | Memeriksa status server dan koneksi database |
| `POST` | `/api/auth/register` | Tidak | Registrasi akun pengguna baru |
| `POST` | `/api/auth/login` | Tidak | Login pengguna dan mendapatkan JWT token |
| `GET` | `/api/auth/me` | **Wajib** | Mengambil profil pengguna yang sedang login |
| `POST` | `/api/notes` | **Wajib** | Membuat catatan baru |
| `GET` | `/api/notes` | **Wajib** | Mengambil daftar catatan (`?search=`, `?is_pinned=`, `?color=`) |
| `GET` | `/api/notes/:id` | **Wajib** | Mengambil detail satu catatan milik pengguna |
| `PUT` | `/api/notes/:id` | **Wajib** | Memperbarui isi/pengaturan catatan |
| `DELETE` | `/api/notes/:id` | **Wajib** | Menghapus catatan secara permanen |
| `PATCH` | `/api/notes/:id/pin` | **Wajib** | Mengubah status *pin* catatan |
| `PATCH` | `/api/notes/:id/privacy` | **Wajib** | Mengubah status privasi (`is_private`) catatan |

---

## 7. Dokumentasi Teknis Lengkap

- [frontend/README.md](frontend/README.md) — Dokumentasi arsitektur dan penggunaan aplikasi Flutter.
- [backend/docs/API_DOCUMENTATION.md](backend/docs/API_DOCUMENTATION.md) — Spesifikasi lengkap seluruh endpoint REST API.
- [backend/docs/PROJECT_STRUCTURE.md](backend/docs/PROJECT_STRUCTURE.md) — Penjelasan fungsi setiap folder dan file backend.
- [backend/docs/DEVELOPMENT_GUIDE.md](backend/docs/DEVELOPMENT_GUIDE.md) — Panduan modifikasi dan pengembangan fitur.
- [backend/docs/FLUTTER_INTEGRATION_GUIDE.md](backend/docs/FLUTTER_INTEGRATION_GUIDE.md) — Panduan integrasi Flutter dengan REST API.
