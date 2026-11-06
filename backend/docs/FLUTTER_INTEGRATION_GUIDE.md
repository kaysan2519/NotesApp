# Panduan Integrasi Flutter — MyNotes REST API

Dokumen ini disiapkan sebagai acuan lengkap ketika tahap pengembangan **Frontend Flutter** (`./frontend`) dimulai.

---

## 1. Konfigurasi Base URL API pada Flutter

Saat menjalankan backend secara lokal pada port `3000`, gunakan Base URL sesuai target device Flutter yang digunakan:

| Target Device / Emulator | Base URL API |
|---|---|
| **Android Emulator** | `http://10.0.2.2:3000/api` |
| **iOS Simulator** | `http://localhost:3000/api` |
| **Flutter Desktop / Web** | `http://localhost:3000/api` |
| **Perangkat Fisik (HP Asli via Wi-Fi)** | `http://<IP_LAPTOP_ANDA>:3000/api` (contoh: `http://192.168.1.10:3000/api`) |

---

## 2. Penyimpanan & Pengiriman JWT di Flutter

### A. Menyimpan Token Setelah Login / Register
Saat endpoint `POST /api/auth/login` atau `POST /api/auth/register` mengembalikan status `200` / `201`:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "username": "jessica",
      "email": "jessica@example.com"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```
Simpan nilai `data.token` ke penyimpanan lokal perangkat menggunakan `flutter_secure_storage` atau `shared_preferences`.

### B. Mengirim JWT pada Setiap Request
Sertakan header berikut pada seluruh request ke `/api/auth/me` dan `/api/notes`:
```dart
Map<String, String> getAuthHeaders(String token) {
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
```

### C. Menangani Token Expired (`401 Unauthorized`) & Logout
1. **Saat Startup Aplikasi (Splash Screen):**
   - Periksa apakah token tersimpan di penyimpanan lokal.
   - Jika ada, panggil `GET /api/auth/me`.
   - Jika response `200 OK`, arahkan pengguna ke halaman **Home / My Notes**.
   - Jika response `401 Unauthorized`, hapus token lokal dan arahkan pengguna ke halaman **Login**.
2. **Saat Operasi Notes Mengembalikan `401 Unauthorized`:**
   - Hapus token dari penyimpanan lokal.
   - Tampilkan pesan sesi telah berakhir dan arahkan pengguna kembali ke halaman **Login**.
3. **Saat Pengguna Menekan Tombol Logout:**
   - Hapus token JWT dan data user dari penyimpanan lokal, lalu navigasikan ke halaman **Login** (`pushAndRemoveUntil`).

---

## 3. Pemetaan Halaman Flutter ke Endpoint API

### 1. Halaman Register
- **Endpoint:** `POST /api/auth/register`
- **Body JSON:**
  ```json
  {
    "username": "jessica",
    "email": "jessica@example.com",
    "password": "password123"
  }
  ```
- **Sukses (`201`):** Simpan `data.token` lalu navigasi ke **Home Screen** (atau ke **Login Screen** sesuai alur UI).

### 2. Halaman Login
- **Endpoint:** `POST /api/auth/login`
- **Body JSON:**
  ```json
  {
    "email": "jessica@example.com",
    "password": "password123"
  }
  ```
- **Sukses (`200`):** Simpan `data.token` dan `data.user`, lalu navigasi ke **Home Screen**.

### 3. Halaman Home / My Notes (beserta Search & Filter)
- **Mengambil Semua Catatan:** `GET /api/notes`
- **Mencari Catatan:** `GET /api/notes?search=<kata_kunci>`
- **Filter Catatan Pinned:** `GET /api/notes?is_pinned=true`
- **Filter Warna Catatan:** `GET /api/notes?color=%23A5F3AD`
- **Response (`200`):** `data` berupa `List` objek catatan yang sudah terurut (`is_pinned` di atas, lalu `updated_at` terbaru).

### 4. Halaman Create Note
- **Endpoint:** `POST /api/notes`
- **Body JSON:**
  ```json
  {
    "title": "Judul Catatan",
    "content": "Isi catatan...",
    "color": "#A5F3AD",
    "is_pinned": false,
    "is_private": true
  }
  ```

### 5. Halaman Note Detail
- **Endpoint:** `GET /api/notes/:id`
- **Menghapus Catatan dari Halaman Detail:** `DELETE /api/notes/:id`

### 6. Halaman Edit Note
- **Endpoint:** `PUT /api/notes/:id`
- **Body JSON:**
  ```json
  {
    "title": "Judul Baru",
    "content": "Isi catatan yang diperbarui",
    "color": "#D8A7F5",
    "is_pinned": true,
    "is_private": true
  }
  ```

### 7. Pengaturan Cepat (Pin & Private Settings)
- **Toggle Pin:** `PATCH /api/notes/:id/pin` dengan body `{ "is_pinned": true }` atau `{ "is_pinned": false }`.
- **Toggle Private:** `PATCH /api/notes/:id/privacy` dengan body `{ "is_private": true }` atau `{ "is_private": false }`.

---

## 4. Konversi Palet Warna Catatan di Flutter

Backend memvalidasi kode warna hex berikut (`backend/src/config/note-colors.ts`). Gunakan konstanta yang sama di Flutter:

| Nama Warna | Hex String (API) | Kode `Color` di Flutter (Dart) |
|---|---|---|
| Mint Green (Default) | `#A5F3AD` | `Color(0xFFA5F3AD)` |
| Lavender | `#D8A7F5` | `Color(0xFFD8A7F5)` |
| Yellow | `#F6DB59` | `Color(0xFFF6DB59)` |
| Pink | `#F2A3A6` | `Color(0xFFF2A3A6)` |
| Turquoise | `#70DDC7` | `Color(0xFF70DDC7)` |
| Blue | `#83BCEB` | `Color(0xFF83BCEB)` |
| Gray | `#D9D9D9` | `Color(0xFFD9D9D9)` |
| White | `#FFFFFF` | `Color(0xFFFFFFFF)` |
