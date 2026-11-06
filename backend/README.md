# MyNotes Backend — Express.js + TypeScript + MySQL REST API

Direktori ini berisi source code **Backend REST API** untuk aplikasi **MyNotes**.

## Quick Start (Local Development — XAMPP)

```bash
# 1. Instal dependencies
npm install

# 2. Salin konfigurasi environment
cp .env.example .env

# 3. Jalankan migrasi database MySQL
npm run migrate

# 4. Jalankan server development
npm run dev
```

## Konfigurasi Database Production (Aiven MySQL & Vercel)

Backend mendukung koneksi MySQL lokal (XAMPP tanpa SSL) maupun koneksi Cloud MySQL terenkripsi (Aiven MySQL dengan SSL/TLS `rejectUnauthorized: true`).

### 1. Encode Aiven CA Certificate (`ca.pem`) ke Base64
Jangan menyimpan file `ca.pem` ke dalam Git. Konversikan isi file `ca.pem` menjadi string Base64 satu baris:

- **PowerShell (Windows):**
  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\ca.pem"))
  ```
- **Bash (Linux / macOS / Git Bash):**
  ```bash
  base64 -w 0 path/to/ca.pem
  ```

### 2. Environment Variables Production (Vercel)
Atur variabel berikut pada dashboard **Vercel Project Settings -> Environment Variables** (gunakan nilai kredensial asli hanya di dashboard Vercel, bukan di kode/Git):

```env
NODE_ENV=production
PORT=3000

DB_HOST=<YOUR_AIVEN_MYSQL_HOST>
DB_PORT=17374
DB_USER=avnadmin
DB_PASSWORD=<YOUR_AIVEN_MYSQL_PASSWORD>
DB_NAME=defaultdb
DB_SSL=true
DB_SSL_CA_BASE64=<BASE64_ENCODED_AIVEN_CA_PEM>

JWT_SECRET=<YOUR_STRONG_PRODUCTION_JWT_SECRET>
JWT_EXPIRES_IN=1d
BCRYPT_SALT_ROUNDS=12
CORS_ORIGIN=*
```

> **Catatan:** Saat `DB_SSL=true`, aplikasi wajib menerima `DB_SSL_CA_BASE64` yang valid. Aplikasi akan men-decode sertifikat CA dari Base64 dan mengaktifkan `ssl: { ca, rejectUnauthorized: true }` pada `mysql2/promise`. Untuk development lokal dengan XAMPP, biarkan `DB_SSL=false` dan `DB_SSL_CA_BASE64=` kosong.

## Daftar Script (`package.json`)

- `npm run dev` — Menjalankan server development pada `http://localhost:3000`.
- `npm run typecheck` — Menjalankan pemeriksaan tipe TypeScript (`strict: true`).
- `npm run build` — Membangun kode production ke dalam folder `dist/`.
- `npm start` — Menjalankan server production dari `dist/server.js`.
- `npm run migrate` — Menjalankan migrasi SQL database secara idempotent.
- `npm test` — Menjalankan 28 pengujian integrasi & konfigurasi (Vitest + Supertest) menggunakan database uji lokal `mynotes_test_db`.

## Dokumentasi Lengkap

Silakan baca dokumentasi teknis di dalam direktori `docs/`:
- [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)
- [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)
- [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)
- [docs/FLUTTER_INTEGRATION_GUIDE.md](docs/FLUTTER_INTEGRATION_GUIDE.md)

