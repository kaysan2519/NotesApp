import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError, sendError } from '../utils/response.util';
import { env } from '../config/env';

interface DatabaseError {
  code?: string;
  errno?: number;
  sqlState?: string;
  message?: string;
}

interface BodyParserError extends Error {
  status?: number;
  type?: string;
  body?: unknown;
}

/**
 * Memeriksa apakah error berasal dari operasi MySQL database.
 */
function isDatabaseError(err: unknown): err is DatabaseError {
  if (typeof err !== 'object' || err === null) {
    return false;
  }
  const maybeDbErr = err as DatabaseError;
  return (
    typeof maybeDbErr.code === 'string' &&
    (maybeDbErr.code.startsWith('ER_') ||
      maybeDbErr.code === 'ECONNREFUSED' ||
      maybeDbErr.code === 'PROTOCOL_CONNECTION_LOST' ||
      maybeDbErr.code === 'ETIMEDOUT')
  );
}

/**
 * Middleware terpusat untuk menangani seluruh error di aplikasi Express.
 * Menangani ZodError, AppError, BodyParserError, dan DatabaseError secara aman
 * tanpa membocorkan stack trace, struktur tabel, atau query SQL ke client.
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
      : 'Input request tidak valid';
    sendError(res, message, 400, null);
    return;
  }

  // 2. Tangani error operasional dari AppError
  if (err instanceof AppError) {
    sendError(res, err.message, err.statusCode, null);
    return;
  }

  // 3. Tangani error ukuran payload terlalu besar atau format JSON rusak
  const bodyErr = err as BodyParserError;
  if (bodyErr?.type === 'entity.too.large' || bodyErr?.status === 413) {
    sendError(res, 'Ukuran request body melebihi batas maksimum (100KB)', 413, null);
    return;
  }

  if (
    err instanceof SyntaxError &&
    bodyErr?.status === 400 &&
    'body' in bodyErr
  ) {
    sendError(res, 'Format JSON pada request body tidak valid', 400, null);
    return;
  }

  // 4. Tangani error MySQL Database tanpa membocorkan query atau informasi sensitif
  if (isDatabaseError(err)) {
    if (err.code === 'ER_DUP_ENTRY') {
      sendError(res, 'Data yang dikirimkan sudah terdaftar (duplikat)', 409, null);
      return;
    }

    if (
      err.code === 'ER_NO_REFERENCED_ROW' ||
      err.code === 'ER_NO_REFERENCED_ROW_2' ||
      err.code === 'ER_ROW_IS_REFERENCED' ||
      err.code === 'ER_ROW_IS_REFERENCED_2'
    ) {
      sendError(res, 'Referensi data terkait tidak valid (foreign key constraint)', 400, null);
      return;
    }

    if (
      err.code === 'ECONNREFUSED' ||
      err.code === 'PROTOCOL_CONNECTION_LOST' ||
      err.code === 'ETIMEDOUT'
    ) {
      sendError(res, 'Koneksi ke database sedang bermasalah', 503, null);
      return;
    }

    if (env.NODE_ENV !== 'test') {
      console.error('[DATABASE ERROR]:', { code: err.code, errno: err.errno });
    }
    sendError(res, 'Terjadi kesalahan pada pemrosesan data database', 500, null);
    return;
  }

  // 5. Log error tak terduga pada selain environment test (tanpa mencetak secret/token)
  if (env.NODE_ENV !== 'test') {
    const safeMessage = err instanceof Error ? err.message : 'Unknown error';
    console.error('[UNHANDLED ERROR]:', safeMessage);
  }

  // 6. Kembalikan 500 Internal Server Error tanpa stack trace
  sendError(res, 'Internal Server Error', 500, null);
}
