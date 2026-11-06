# MyNotes Frontend — Flutter Mobile Application

Direktori ini berisi source code lengkap **Frontend Mobile Application** untuk **MyNotes** yang dibangun menggunakan **Flutter**, **Dart**, **Material 3 Custom Design System**, **Riverpod**, **GoRouter**, **Dio**, dan **Flutter Secure Storage**.

---

## 1. Fitur Utama Aplikasi Flutter

1. **Splash Screen & Auto-Login:** Memeriksa token JWT yang tersimpan secara aman di `flutter_secure_storage` dan memvalidasinya ke `GET /api/auth/me`.
2. **Authentication (Login & Register):**
   - Form registrasi (`username`, `email`, `password`) terhubung ke `POST /api/auth/register`.
   - Form login (`email`, `password`) terhubung ke `POST /api/auth/login`.
   - Penanganan otomatis apabila sesi berakhir (`401 Unauthorized` -> bersihkan token & arahkan ke Login).
   - Pengaturan Base URL API langsung dari ikon konfigurasi di halaman Login (untuk kemudahan perpindahan antara Android Emulator dan HP fisik).
3. **Home / My Notes Dashboard:**
   - Menampilkan daftar catatan milik pengguna yang sedang login dari `GET /api/notes`.
   - Kartu catatan berwarna pastel sesuai warna yang tersimpan di database MySQL.
   - Catatan dengan status *Pinned* otomatis tampil di urutan paling atas.
   - Pencarian *real-time* (`?search=`) berdasarkan judul maupun isi catatan.
   - Filter cepat antara **All Notes** dan **Pinned** (`?is_pinned=true`).
   - *Pull-to-refresh* dan tombol refresh instan.
4. **Create, Edit, & Note Detail:**
   - Membuat catatan baru (`POST /api/notes`) dengan validasi judul, isi, pilihan 8 warna kartu pastel, pengaturan *Pin*, dan *Private*.
   - Membaca detail catatan (`GET /api/notes/:id`).
   - Mengedit catatan (`PUT /api/notes/:id`).
5. **Note Settings & Delete Confirmation:**
   - Mengubah warna kartu catatan melalui `ColorPickerBar`.
   - Mengubah status *Pin* melalui `PATCH /api/notes/:id/pin`.
   - Mengubah status *Private* melalui `PATCH /api/notes/:id/privacy`.
   - Menghapus catatan secara permanen (`DELETE /api/notes/:id`) dengan dialog konfirmasi.
6. **Profile & Logout:**
   - Menampilkan informasi profil pengguna (`username`, `email`, jumlah catatan) dan tombol **Logout** yang menghapus JWT dari penyimpanan aman.

---

## 2. Arsitektur Folder (`frontend/lib/`)

```text
frontend/lib/
├── config/
│   └── api_config.dart                 # Konfigurasi terpusat Base URL API & daftar endpoint
├── core/
│   ├── constants/
│   │   └── app_colors.dart             # Sistem palet warna pastel & konversi kode Hex
│   ├── routing/
│   │   └── app_router.dart             # Konfigurasi GoRouter & auth redirect guard
│   ├── theme/
│   │   └── app_theme.dart              # Material 3 Custom Design System
│   └── utils/
│       ├── api_exception.dart          # Penanganan error HTTP/Dio terstandarisasi
│       ├── date_formatter.dart         # Pemformatan tanggal menggunakan intl
│       └── validators.dart             # Validasi input form (selaras dengan Zod backend)
├── models/
│   ├── user_model.dart                 # Model data pengguna (UserModel)
│   └── note_model.dart                 # Model data catatan (NoteModel)
├── providers/
│   ├── auth_provider.dart              # State management autentikasi (Riverpod)
│   └── notes_provider.dart             # State management CRUD & filter catatan (Riverpod)
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart          # Halaman Splash & pemeriksaan sesi JWT
│   ├── auth/
│   │   ├── login_screen.dart           # Halaman Login
│   │   └── register_screen.dart        # Halaman Register
│   ├── home/
│   │   ├── home_screen.dart            # Halaman utama My Notes Dashboard
│   │   └── profile_sheet.dart          # Bottom sheet profil pengguna & Logout
│   └── notes/
│       ├── note_detail_screen.dart     # Halaman membaca detail catatan
│       ├── note_editor_screen.dart     # Halaman membuat & mengedit catatan
│       └── note_settings_sheet.dart    # Bottom sheet pengaturan warna, pin, privacy, & hapus
├── services/
│   ├── api/
│   │   ├── dio_client.dart             # HTTP client Dio + interceptor Bearer JWT & 401 handler
│   │   ├── auth_api_service.dart       # Layanan API autentikasi (/api/auth/*)
│   │   └── notes_api_service.dart      # Layanan API catatan (/api/notes/*)
│   └── storage/
│       └── token_storage_service.dart  # Penyimpanan JWT menggunakan flutter_secure_storage
├── widgets/
│   ├── pastel_background.dart          # Background krem dengan ornamen abstrak pastel
│   ├── pill_button.dart                # Tombol hitam berbentuk pill (#202020)
│   ├── custom_text_field.dart          # Input field modern dengan toggle password
│   ├── note_card.dart                  # Kartu catatan pastel untuk Grid Dashboard
│   └── color_picker_bar.dart           # Pemilih 8 warna kartu catatan
└── main.dart                           # Entry point aplikasi Flutter
```

---

## 3. Cara Menjalankan Backend dan Flutter Secara Bersamaan

### Langkah 1 — Jalankan MySQL & Backend Server
Buka terminal pertama pada folder `backend/`:
```bash
cd backend
npm install
npm run migrate
npm run dev
```
Pastikan server berjalan pada `http://localhost:3000`.

### Langkah 2 — Jalankan Aplikasi Flutter
Buka terminal kedua pada folder `frontend/`:
```bash
cd frontend
flutter pub get
flutter run
```

### Konfigurasi Base URL Sesuai Target Device:
- **Android Emulator:** Otomatis menggunakan `http://10.0.2.2:3000/api` (tidak perlu konfigurasi tambahan).
- **Web / Desktop / iOS Simulator:** Otomatis menggunakan `http://localhost:3000/api`.
- **Perangkat Fisik (HP Android via Wi-Fi yang sama):**
  Anda dapat menjalankan dengan `--dart-define`:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.X:3000/api
  ```
  Atau ketuk ikon **Pengaturan Server API** di pojok kanan atas halaman Login pada aplikasi.

---

## 4. Perintah Pengujian & Build

```bash
# Memeriksa kualitas kode & analisis statis
flutter analyze

# Menjalankan seluruh unit, service, dan widget test
flutter test

# Membangun file APK Debug Android
flutter build apk --debug
```
