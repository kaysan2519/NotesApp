# Dokumentasi REST API — MyNotes Backend

## 1. Informasi Umum

- **Base URL (Lokal):** `http://localhost:3000/api`
- **Format Pertukaran Data:** `application/json`
- **Skema Autentikasi:** Bearer Token (JSON Web Token / JWT)

### Standar Format Response JSON

Seluruh endpoint MyNotes selalu mengembalikan struktur JSON yang konsisten:

**Response Sukses (`200 OK` / `201 Created`):**
```json
{
  "success": true,
  "message": "Pesan deskriptif",
  "data": {}
}
```

**Response Error (`400`, `401`, `404`, `409`, `413`, `429`, `500`, `503`):**
```json
{
  "success": false,
  "message": "Pesan penjelasan error",
  "data": null
}
```

### Header Autentikasi (Untuk Endpoint yang Dilindungi JWT)

```http
Content-Type: application/json
Authorization: Bearer <YOUR_JWT_TOKEN>
```

---

## 2. Health Check Endpoint

### `GET /api/health`
Memeriksa apakah server API dan koneksi database MySQL berjalan dengan baik.

- **Autentikasi JWT:** Tidak diperlukan
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "MyNotes API is running",
    "data": {
      "status": "healthy",
      "database": "connected"
    }
  }
  ```

---

## 3. Authentication Endpoints (`/api/auth`)

### A. Register Pengguna Baru
- **Endpoint:** `POST /api/auth/register`
- **Autentikasi JWT:** Tidak diperlukan
- **Request Headers:** `Content-Type: application/json`
- **Request Body:**
  ```json
  {
    "username": "jessica",
    "email": "jessica@example.com",
    "password": "password123"
  }
  ```
- **Aturan Validasi:**
  - `username`: wajib, 2–50 karakter.
  - `email`: wajib, format email valid, maks 191 karakter, otomatis dikonversi ke huruf kecil (*lowercase*).
  - `password`: wajib, 6–100 karakter (disimpan sebagai *bcrypt hash*).
- **Response `201 Created`:**
  ```json
  {
    "success": true,
    "message": "User registered successfully",
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
- **Response Error:**
  - `400 Bad Request` — Input tidak valid.
  - `409 Conflict` — Email sudah terdaftar.

---

### B. Login Pengguna
- **Endpoint:** `POST /api/auth/login`
- **Autentikasi JWT:** Tidak diperlukan (dilindungi *Rate Limiter* anti brute-force)
- **Request Headers:** `Content-Type: application/json`
- **Request Body:**
  ```json
  {
    "email": "jessica@example.com",
    "password": "password123"
  }
  ```
- **Response `200 OK`:**
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
- **Response Error:**
  - `400 Bad Request` — Format email/password tidak valid.
  - `401 Unauthorized` — Email tidak ditemukan atau password salah.
  - `429 Too Many Requests` — Terlalu banyak percobaan login.

---

### C. Get Current User Profile (`/me`)
- **Endpoint:** `GET /api/auth/me`
- **Autentikasi JWT:** **Wajib** (`Authorization: Bearer <token>`)
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Current user retrieved successfully",
    "data": {
      "user": {
        "id": 1,
        "username": "jessica",
        "email": "jessica@example.com",
        "created_at": "2026-11-06T03:00:00.000Z",
        "updated_at": "2026-11-06T03:00:00.000Z"
      }
    }
  }
  ```
- **Response Error:**
  - `401 Unauthorized` — Token tidak dikirim, tidak valid, atau sudah kedaluwarsa (*expired*).
  - `404 Not Found` — Pengguna tidak lagi ditemukan di database.

---

### D. Logout
- Pada arsitektur JWT *stateless* mobile, proses **Logout** dilakukan di sisi aplikasi Flutter dengan menghapus token JWT dari penyimpanan lokal (*secure storage* / *shared preferences*).

---

## 4. Notes Management Endpoints (`/api/notes`)

> **Penting:** Seluruh endpoint `/api/notes` **wajib** menyertakan header `Authorization: Bearer <YOUR_JWT_TOKEN>`. Setiap operasi secara ketat memeriksa kepemilikan (`user_id` dari JWT).

### Daftar Palet Warna Catatan Resmi (`color`)

| Nama Warna | Kode Hex | Keterangan |
|---|---|---|
| Mint Green | `#A5F3AD` | Warna default |
| Lavender | `#D8A7F5` | Ungu pastel |
| Yellow | `#F6DB59` | Kuning pastel |
| Pink | `#F2A3A6` | Merah muda pastel |
| Turquoise | `#70DDC7` | Toska pastel |
| Blue | `#83BCEB` | Biru muda pastel |
| Gray | `#D9D9D9` | Abu-abu muda |
| White | `#FFFFFF` | Putih bersih |

---

### A. Create Note
- **Endpoint:** `POST /api/notes`
- **Autentikasi JWT:** **Wajib**
- **Request Body:**
  ```json
  {
    "title": "Business Team Meeting",
    "content": "Persiapan meeting bersama tim.",
    "color": "#A5F3AD",
    "is_pinned": false,
    "is_private": true
  }
  ```
  *(Catatan: `content`, `color`, `is_pinned`, dan `is_private` bersifat opsional dan memiliki nilai default).*
- **Response `201 Created`:**
  ```json
  {
    "success": true,
    "message": "Note created successfully",
    "data": {
      "id": 1,
      "user_id": 1,
      "title": "Business Team Meeting",
      "content": "Persiapan meeting bersama tim.",
      "color": "#A5F3AD",
      "is_pinned": false,
      "is_private": true,
      "created_at": "2026-11-06T03:10:00.000Z",
      "updated_at": "2026-11-06T03:10:00.000Z"
    }
  }
  ```

---

### B. Get All Notes (Beserta Search & Filter)
- **Endpoint:** `GET /api/notes`
- **Autentikasi JWT:** **Wajib**
- **Query Parameters (Opsional):**
  - `search` — Mencari kata kunci pada `title` atau `content` (contoh: `/api/notes?search=meeting`).
  - `is_pinned` — Filter berdasarkan status pin: `true` atau `false` (contoh: `/api/notes?is_pinned=true`).
  - `color` — Filter berdasarkan kode hex warna catatan (contoh: `/api/notes?color=%23A5F3AD`).
- **Urutan Data:** Catatan dengan `is_pinned = true` selalu tampil di urutan teratas, diikuti urutan `updated_at` terbaru.
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Notes retrieved successfully",
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "title": "Business Team Meeting",
        "content": "Persiapan meeting bersama tim.",
        "color": "#A5F3AD",
        "is_pinned": false,
        "is_private": true,
        "created_at": "2026-11-06T03:10:00.000Z",
        "updated_at": "2026-11-06T03:10:00.000Z"
      }
    ]
  }
  ```

---

### C. Get Note Detail
- **Endpoint:** `GET /api/notes/:id`
- **Autentikasi JWT:** **Wajib**
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Note retrieved successfully",
    "data": {
      "id": 1,
      "user_id": 1,
      "title": "Business Team Meeting",
      "content": "Persiapan meeting bersama tim.",
      "color": "#A5F3AD",
      "is_pinned": false,
      "is_private": true,
      "created_at": "2026-11-06T03:10:00.000Z",
      "updated_at": "2026-11-06T03:10:00.000Z"
    }
  }
  ```
- **Response Error:**
  - `404 Not Found` — Catatan tidak ditemukan atau bukan milik pengguna yang sedang login.

---

### D. Update Note
- **Endpoint:** `PUT /api/notes/:id`
- **Autentikasi JWT:** **Wajib**
- **Request Body:**
  ```json
  {
    "title": "Updated Business Meeting",
    "content": "Agenda meeting telah diperbarui.",
    "color": "#D8A7F5",
    "is_pinned": true,
    "is_private": true
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Note updated successfully",
    "data": {
      "id": 1,
      "user_id": 1,
      "title": "Updated Business Meeting",
      "content": "Agenda meeting telah diperbarui.",
      "color": "#D8A7F5",
      "is_pinned": true,
      "is_private": true,
      "created_at": "2026-11-06T03:10:00.000Z",
      "updated_at": "2026-11-06T03:15:00.000Z"
    }
  }
  ```

---

### E. Delete Note
- **Endpoint:** `DELETE /api/notes/:id`
- **Autentikasi JWT:** **Wajib**
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Note deleted successfully",
    "data": null
  }
  ```

---

### F. Toggle / Set Pin Note
- **Endpoint:** `PATCH /api/notes/:id/pin`
- **Autentikasi JWT:** **Wajib**
- **Request Body:**
  ```json
  {
    "is_pinned": true
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Note pin status updated successfully",
    "data": {
      "id": 1,
      "user_id": 1,
      "title": "Updated Business Meeting",
      "content": "Agenda meeting telah diperbarui.",
      "color": "#D8A7F5",
      "is_pinned": true,
      "is_private": true,
      "created_at": "2026-11-06T03:10:00.000Z",
      "updated_at": "2026-11-06T03:16:00.000Z"
    }
  }
  ```

---

### G. Toggle / Set Private Setting
- **Endpoint:** `PATCH /api/notes/:id/privacy`
- **Autentikasi JWT:** **Wajib**
- **Request Body:**
  ```json
  {
    "is_private": true
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Note privacy status updated successfully",
    "data": {
      "id": 1,
      "user_id": 1,
      "title": "Updated Business Meeting",
      "content": "Agenda meeting telah diperbarui.",
      "color": "#D8A7F5",
      "is_pinned": true,
      "is_private": true,
      "created_at": "2026-11-06T03:10:00.000Z",
      "updated_at": "2026-11-06T03:17:00.000Z"
    }
  }
  ```

---

## 5. Contoh Pengujian Menggunakan Postman

1. **Langkah 1 — Login / Register:**
   - Buat request `POST http://localhost:3000/api/auth/register` atau `POST http://localhost:3000/api/auth/login`.
   - Pilih tab **Body** -> **raw** -> pilih **JSON**.
   - Kirim request dan salin nilai `data.token` dari response.
2. **Langkah 2 — Mengatur Authorization di Postman:**
   - Buka tab **Authorization** pada request `/api/notes`.
   - Pilih **Auth Type**: `Bearer Token`.
   - Tempelkan token JWT pada kolom **Token**.
3. **Langkah 3 — Menguji Operasi CRUD Notes:**
   - Kirim request `POST http://localhost:3000/api/notes` untuk menambah catatan.
   - Kirim request `GET http://localhost:3000/api/notes?search=meeting` untuk menguji fitur pencarian.
