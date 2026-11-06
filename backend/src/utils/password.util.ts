import bcrypt from 'bcrypt';
import { env } from '../config/env';

/**
 * Mengubah plaintext password menjadi bcrypt hash yang aman.
 */
export async function hashPassword(plainPassword: string): Promise<string> {
  return bcrypt.hash(plainPassword, env.BCRYPT_SALT_ROUNDS);
}

/**
 * Memverifikasi kecocokan plaintext password dengan bcrypt hash dari database.
 */
export async function verifyPassword(
  plainPassword: string,
  hashedPassword: string
): Promise<boolean> {
  return bcrypt.compare(plainPassword, hashedPassword);
}
