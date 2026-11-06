import path from 'path';
import dotenv from 'dotenv';
import { z } from 'zod';

// Load environment variables from backend/.env
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const booleanEnvSchema = z.preprocess((val) => {
  if (typeof val === 'boolean') {
    return val;
  }
  if (typeof val === 'string') {
    const normalized = val.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') {
      return true;
    }
    if (normalized === 'false' || normalized === '0' || normalized === '') {
      return false;
    }
  }
  if (val === undefined || val === null) {
    return false;
  }
  return val;
}, z.boolean({ message: 'Nilai harus berupa boolean (true/false)' }));

export const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    PORT: z.coerce.number().int().positive().default(3000),

    DB_HOST: z.string().min(1, 'DB_HOST wajib diisi'),
    DB_PORT: z.coerce.number().int().positive().default(3306),
    DB_USER: z.string().min(1, 'DB_USER wajib diisi'),
    DB_PASSWORD: z.string().default(''),
    DB_NAME: z.string().min(1, 'DB_NAME wajib diisi'),
    DB_SSL: booleanEnvSchema.default(false),
    DB_SSL_CA_BASE64: z.string().trim().default(''),

    JWT_SECRET: z.string().min(1, 'JWT_SECRET wajib diisi di dalam file .env'),
    JWT_EXPIRES_IN: z.string().min(1, 'JWT_EXPIRES_IN wajib diisi').default('1d'),

    BCRYPT_SALT_ROUNDS: z.coerce.number().int().min(4).max(20).default(12),

    CORS_ORIGIN: z.string().min(1).default('*'),
  })
  .superRefine((data, ctx) => {
    if (data.DB_SSL) {
      if (!data.DB_SSL_CA_BASE64 || data.DB_SSL_CA_BASE64.trim().length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['DB_SSL_CA_BASE64'],
          message:
            'DB_SSL_CA_BASE64 wajib diisi ketika DB_SSL=true (wajib untuk koneksi SSL/TLS production seperti Aiven MySQL)',
        });
        return;
      }

      const decodedCa = Buffer.from(data.DB_SSL_CA_BASE64.trim(), 'base64')
        .toString('utf-8')
        .trim();

      if (!decodedCa.includes('BEGIN CERTIFICATE') || !decodedCa.includes('END CERTIFICATE')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['DB_SSL_CA_BASE64'],
          message:
            'DB_SSL_CA_BASE64 harus berisi CA certificate format PEM yang di-encode ke Base64 secara valid',
        });
      }
    }
  });

export type EnvConfig = z.infer<typeof envSchema>;

/**
 * Memvalidasi objek environment variables terhadap envSchema.
 */
export function parseEnv(rawEnv: NodeJS.ProcessEnv | Record<string, unknown>) {
  return envSchema.safeParse(rawEnv);
}

const parsedEnv = parseEnv(process.env);

if (!parsedEnv.success) {
  const formattedErrors = parsedEnv.error.issues
    .map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`)
    .join('\n');

  console.error(
    `[CONFIG ERROR] Konfigurasi environment (.env) tidak valid atau belum lengkap:\n${formattedErrors}\nPastikan file backend/.env sudah dibuat berdasarkan backend/.env.example.`
  );
  process.exit(1);
}

export const env: EnvConfig = parsedEnv.data;

