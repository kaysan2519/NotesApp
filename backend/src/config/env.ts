import path from 'path';
import dotenv from 'dotenv';
import { z } from 'zod';

// Load environment variables from backend/.env
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),

  DB_HOST: z.string().min(1, 'DB_HOST wajib diisi'),
  DB_PORT: z.coerce.number().int().positive().default(3306),
  DB_USER: z.string().min(1, 'DB_USER wajib diisi'),
  DB_PASSWORD: z.string().default(''),
  DB_NAME: z.string().min(1, 'DB_NAME wajib diisi'),

  JWT_SECRET: z.string().min(1, 'JWT_SECRET wajib diisi di dalam file .env'),
  JWT_EXPIRES_IN: z.string().min(1, 'JWT_EXPIRES_IN wajib diisi').default('1d'),

  BCRYPT_SALT_ROUNDS: z.coerce.number().int().min(4).max(20).default(12),

  CORS_ORIGIN: z.string().min(1).default('*'),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  const formattedErrors = parsedEnv.error.issues
    .map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`)
    .join('\n');

  console.error(
    `[CONFIG ERROR] Konfigurasi environment (.env) tidak valid atau belum lengkap:\n${formattedErrors}\nPastikan file backend/.env sudah dibuat berdasarkan backend/.env.example.`
  );
  process.exit(1);
}

export const env = parsedEnv.data;
export type EnvConfig = z.infer<typeof envSchema>;
