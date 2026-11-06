import mysql, { Pool, PoolConnection, PoolOptions, SslOptions } from 'mysql2/promise';
import { env, EnvConfig } from './env';

/**
 * Membangun konfigurasi SSL/TLS untuk mysql2/promise.
 * - Jika DB_SSL=false (default lokal XAMPP), mengembalikan undefined (tanpa SSL).
 * - Jika DB_SSL=true (production Aiven MySQL), men-decode DB_SSL_CA_BASE64
 *   dari Base64 menjadi string PEM dan mengaktifkan rejectUnauthorized: true.
 */
export function buildDatabaseSslOptions(
  config: Pick<EnvConfig, 'DB_SSL' | 'DB_SSL_CA_BASE64' | 'NODE_ENV'> = env
): SslOptions | undefined {
  if (!config.DB_SSL) {
    return undefined;
  }

  const rawBase64 = config.DB_SSL_CA_BASE64?.trim() ?? '';
  if (!rawBase64) {
    throw new Error(
      'DB_SSL_CA_BASE64 wajib tersedia saat DB_SSL=true untuk memverifikasi sertifikat CA MySQL.'
    );
  }

  const decodedCa = Buffer.from(rawBase64, 'base64').toString('utf-8').trim();
  if (!decodedCa.includes('BEGIN CERTIFICATE') || !decodedCa.includes('END CERTIFICATE')) {
    throw new Error(
      'DB_SSL_CA_BASE64 tidak valid: hasil decode Base64 bukan sertifikat CA berformat PEM.'
    );
  }

  return {
    ca: decodedCa,
    rejectUnauthorized: true,
  };
}

/**
 * Membangun opsi konfigurasi MySQL Connection Pool berdasarkan environment.
 */
export function buildDatabasePoolOptions(config: EnvConfig = env): PoolOptions {
  const ssl = buildDatabaseSslOptions(config);

  return {
    host: config.DB_HOST,
    port: config.DB_PORT,
    user: config.DB_USER,
    password: config.DB_PASSWORD,
    database: config.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    timezone: 'Z',
    ...(ssl ? { ssl } : {}),
  };
}

/**
 * MySQL Connection Pool utama untuk operasi query aplikasi.
 */
export const pool: Pool = mysql.createPool(buildDatabasePoolOptions(env));

/**
 * Memastikan database (misal: mynotes_db) sudah tersedia.
 * Menggunakan CREATE DATABASE IF NOT EXISTS yang aman dan tidak menghapus data.
 */
export async function ensureDatabaseExists(targetDbName: string = env.DB_NAME): Promise<void> {
  const safeDbName = targetDbName.replace(/[^a-zA-Z0-9_]/g, '');
  const ssl = buildDatabaseSslOptions(env);

  const connection = await mysql.createConnection({
    host: env.DB_HOST,
    port: env.DB_PORT,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    ...(ssl ? { ssl } : {}),
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

