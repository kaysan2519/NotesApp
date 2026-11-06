import { Request, Response, NextFunction } from 'express';
import { ZodTypeAny } from 'zod';

type RequestSource = 'body' | 'query' | 'params';

/**
 * Middleware untuk memvalidasi input request (body, query, atau params) menggunakan Zod.
 */
export function validate(schema: ZodTypeAny, source: RequestSource = 'body') {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const parsed = schema.parse(req[source]);
      req[source] = parsed;
      next();
    } catch (error) {
      next(error);
    }
  };
}
