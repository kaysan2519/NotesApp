import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/response.util';

/**
 * Middleware untuk menangani endpoint/route yang tidak ditemukan (404).
 */
export function notFoundMiddleware(
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  sendError(
    res,
    `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`,
    404,
    null
  );
}
