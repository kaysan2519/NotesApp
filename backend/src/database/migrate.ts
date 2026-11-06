import fs from 'fs';
import path from 'path';
import { Pool, RowDataPacket } from 'mysql2/promise';
import { ensureDatabaseExists, pool, closeDatabasePool } from '../config/database';
import { env } from '../config/env';

interface MigrationRecord extends RowDataPacket {
  filename: string;
}

/**
 * Menjalankan seluruh file migrasi SQL di folder backend/database/migrations
 * secara berurutan dan aman (idempotent, tidak menghapus tabel/data yang sudah ada).
 */
export async function runMigrations(
  targetPool: Pool = pool,
  targetDbName: string = env.DB_NAME
): Promise<string[]> {
  await ensureDatabaseExists(targetDbName);

  const migrationsDir = path.resolve(__dirname, '../../database/migrations');

  if (!fs.existsSync(migrationsDir)) {
    throw new Error(`Direktori migrasi tidak ditemukan: ${migrationsDir}`);
  }

  // Buat tabel pencatat riwayat migrasi jika belum ada
  await targetPool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      filename VARCHAR(255) NOT NULL UNIQUE,
      executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `);

  const [executedRows] = await targetPool.query<MigrationRecord[]>(
    'SELECT filename FROM schema_migrations ORDER BY id ASC'
  );
  const executedSet = new Set(executedRows.map((row) => row.filename));

  const files = fs
    .readdirSync(migrationsDir)
    .filter((file) => file.endsWith('.sql'))
    .sort();

  const newlyExecuted: string[] = [];

  for (const file of files) {
    if (executedSet.has(file)) {
      continue;
    }

    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf-8').trim();

    if (!sql) {
      continue;
    }

    await targetPool.query(sql);
    await targetPool.execute(
      'INSERT INTO schema_migrations (filename) VALUES (?)',
      [file]
    );
    newlyExecuted.push(file);
  }

  return newlyExecuted;
}

// Jika dijalankan langsung melalui CLI (npm run migrate)
if (require.main === module) {
  (async () => {
    try {
      console.log(`[MIGRATION] Memulai migrasi untuk database "${env.DB_NAME}"...`);
      const applied = await runMigrations();
      if (applied.length === 0) {
        console.log('[MIGRATION] Seluruh migrasi sudah pernah dijalankan. Tidak ada perubahan skema.');
      } else {
        console.log(`[MIGRATION] Berhasil menjalankan ${applied.length} migrasi:`, applied.join(', '));
      }
      await closeDatabasePool();
      process.exit(0);
    } catch (error) {
      console.error('[MIGRATION ERROR] Gagal menjalankan migrasi database:', (error as Error).message);
      await closeDatabasePool().catch(() => undefined);
      process.exit(1);
    }
  })();
}
