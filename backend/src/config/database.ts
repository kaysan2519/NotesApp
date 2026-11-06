import mysql, { Pool, PoolConnection } from 'mysql2/promise';
import { env } from './env';

/**
 * MySQL Connection Pool utama untuk operasi query aplikasi.
 */
export const pool: Pool = mysql.createPool({
  host: env.DB_HOST,
  port: env.DB_PORT,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  database: env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: 'Z',
});

/**
 * Memastikan database (misal: mynotes_db) sudah tersedia.
 * Menggunakan CREATE DATABASE IF NOT EXISTS yang aman dan tidak menghapus data.
 */
export async function ensureDatabaseExists(targetDbName: string = env.DB_NAME): Promise<void> {
  const safeDbName = targetDbName.replace(/[^a-zA-Z0-9_]/g, '');
  const connection = await mysql.createConnection({
    host: env.DB_HOST,
    port: env.DB_PORT,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
  });

  try {
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS \`${safeDbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
    );
  } finally {
    await connection.end();
  }
}

/**
 * Menguji koneksi ke MySQL database pool.
 */
export async function testDatabaseConnection(): Promise<boolean> {
  let connection: PoolConnection | null = null;
  try {
    connection = await pool.getConnection();
    await connection.ping();
    return true;
  } catch (error) {
    if (env.NODE_ENV !== 'test') {
      console.error('[DATABASE] Gagal terhubung ke MySQL:', (error as Error).message);
    }
    return false;
  } finally {
    if (connection) {
      connection.release();
    }
  }
}

/**
 * Menutup connection pool secara bersih saat graceful shutdown atau selesai testing.
 */
export async function closeDatabasePool(): Promise<void> {
  await pool.end();
}
