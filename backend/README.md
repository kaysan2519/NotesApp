# MyNotes Backend — Express.js + TypeScript + MySQL REST API

Direktori ini berisi source code **Backend REST API** untuk aplikasi **MyNotes**.

## Quick Start

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

## Daftar Script (`package.json`)

- `npm run dev` — Menjalankan server development pada `http://localhost:3000`.
- `npm run typecheck` — Menjalankan pemeriksaan tipe TypeScript (`strict: true`).
- `npm run build` — Membangun kode production ke dalam folder `dist/`.
- `npm start` — Menjalankan server production dari `dist/server.js`.
- `npm run migrate` — Menjalankan migrasi SQL database secara idempotent.
- `npm test` — Menjalankan 25 pengujian integrasi (Vitest + Supertest) menggunakan database uji `mynotes_test_db`.

## Dokumentasi Lengkap

Silakan baca dokumentasi teknis di dalam direktori `docs/`:
- [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)
- [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)
- [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)
- [docs/FLUTTER_INTEGRATION_GUIDE.md](docs/FLUTTER_INTEGRATION_GUIDE.md)
