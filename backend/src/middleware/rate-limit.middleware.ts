import rateLimit, { RateLimitRequestHandler } from 'express-rate-limit';
import { env } from '../config/env';
import { sendError } from '../utils/response.util';

/**
 * Factory untuk membuat middleware rate limiter dengan response JSON standar MyNotes.
 */
export function createRateLimiter(
  maxRequests: number,
  windowMs: number,
  message: string
): RateLimitRequestHandler {
  return rateLimit({
    windowMs,
    max: maxRequests,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (_req, res) => {
      sendError(res, message, 429, null);
    },
  });
}

/**
 * Rate limiter khusus endpoint Login untuk mencegah serangan brute-force password.
 * Maksimal 10 request per 15 menit pada mode development/production.
 */
export const loginRateLimiter: RateLimitRequestHandler = createRateLimiter(
  env.NODE_ENV === 'test' ? 500 : 10,
  15 * 60 * 1000,
  'Terlalu banyak percobaan login. Silakan coba lagi setelah 15 menit'
);

/**
 * Rate limiter umum untuk seluruh endpoint API.
 */
export const apiRateLimiter: RateLimitRequestHandler = createRateLimiter(
  env.NODE_ENV === 'test' ? 2000 : 200,
  15 * 60 * 1000,
  'Terlalu banyak request dari alamat IP ini. Silakan coba lagi nanti'
);
