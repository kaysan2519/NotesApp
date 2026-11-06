import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt.util';
import { AppError } from '../utils/response.util';

/**
 * Middleware autentikasi JWT.
 * Memeriksa header Authorization: Bearer <token>, memvalidasi signature & masa berlaku,
 * serta menyematkan informasi pengguna pada req.user.
 */
export function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      throw new AppError('Akses ditolak. Token autentikasi tidak ditemukan', 401);
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]?.trim()) {
      throw new AppError('Format Authorization header harus berupa: Bearer <token>', 401);
    }

    const token = parts[1].trim();
    const decodedUser = verifyToken(token);

    req.user = decodedUser;
    next();
  } catch (error) {
    next(error);
  }
}
