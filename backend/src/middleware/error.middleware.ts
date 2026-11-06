import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError, sendError } from '../utils/response.util';
import { env } from '../config/env';

/**
 * Middleware terpusat untuk menangani seluruh error di aplikasi Express.
 * Mencegah kebocoran stack trace atau detail sensitif pada mode production.
 */
export function errorMiddleware(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // 1. Tangani error validasi dari Zod
  if (err instanceof ZodError) {
    const firstIssue = err.issues[0];
    const message = firstIssue
      ? `${firstIssue.path.join('.') ? `${firstIssue.path.join('.')}: ` : ''}${firstIssue.message}`
      : 'Validation error';
    sendError(res, message, 400, null);
    return;
  }

  // 2. Tangani error operasional dari AppError
  if (err instanceof AppError) {
    sendError(res, err.message, err.statusCode, null);
    return;
  }

  // 3. Tangani error JSON body tidak valid dari express.json()
  if (
    err instanceof SyntaxError &&
    'status' in err &&
    (err as { status?: number }).status === 400 &&
    'body' in err
  ) {
    sendError(res, 'Format JSON pada request body tidak valid', 400, null);
    return;
  }

  // 4. Log error tak terduga pada selain environment test
  if (env.NODE_ENV !== 'test') {
    console.error('[UNHANDLED ERROR]:', err);
  }

  // 5. Kembalikan 500 Internal Server Error tanpa membocorkan stack trace ke client
  sendError(res, 'Internal Server Error', 500, null);
}
