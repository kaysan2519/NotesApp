import jwt, { SignOptions, TokenExpiredError, JsonWebTokenError } from 'jsonwebtoken';
import { env } from '../config/env';
import { AuthenticatedUserPayload } from '../types/express';
import { AppError } from './response.util';

/**
 * Membuat JSON Web Token (JWT) untuk pengguna yang berhasil terautentikasi.
 */
export function generateToken(payload: AuthenticatedUserPayload): string {
  const options: SignOptions = {
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn'],
  };

  return jwt.sign(
    {
      id: payload.id,
      email: payload.email,
      username: payload.username,
    },
    env.JWT_SECRET,
    options
  );
}

/**
 * Memverifikasi signature dan masa berlaku JWT.
 * Melempar AppError 401 jika token kedaluwarsa atau tidak valid.
 */
export function verifyToken(token: string): AuthenticatedUserPayload {
  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as jwt.JwtPayload & AuthenticatedUserPayload;

    if (
      typeof decoded !== 'object' ||
      decoded === null ||
      typeof decoded.id !== 'number' ||
      typeof decoded.email !== 'string' ||
      typeof decoded.username !== 'string'
    ) {
      throw new AppError('Payload token tidak valid', 401);
    }

    return {
      id: decoded.id,
      email: decoded.email,
      username: decoded.username,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    if (error instanceof TokenExpiredError) {
      throw new AppError('Token autentikasi telah kedaluwarsa', 401);
    }
    if (error instanceof JsonWebTokenError) {
      throw new AppError('Token autentikasi tidak valid', 401);
    }
    throw new AppError('Gagal memverifikasi token autentikasi', 401);
  }
}
