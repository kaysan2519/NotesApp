import { z } from 'zod';

export const registerSchema = z.object({
  username: z
    .string({ required_error: 'Username wajib diisi' })
    .trim()
    .min(2, 'Username minimal 2 karakter')
    .max(50, 'Username maksimal 50 karakter'),
  email: z
    .string({ required_error: 'Email wajib diisi' })
    .trim()
    .email('Format email tidak valid')
    .max(191, 'Email maksimal 191 karakter')
    .transform((val) => val.toLowerCase()),
  password: z
    .string({ required_error: 'Password wajib diisi' })
    .min(6, 'Password minimal 6 karakter')
    .max(100, 'Password maksimal 100 karakter'),
});

export const loginSchema = z.object({
  email: z
    .string({ required_error: 'Email wajib diisi' })
    .trim()
    .email('Format email tidak valid')
    .max(191, 'Email maksimal 191 karakter')
    .transform((val) => val.toLowerCase()),
  password: z
    .string({ required_error: 'Password wajib diisi' })
    .min(1, 'Password wajib diisi')
    .max(100, 'Password maksimal 100 karakter'),
});
