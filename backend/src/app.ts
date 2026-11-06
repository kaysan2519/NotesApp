import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import { env } from './config/env';
import { testDatabaseConnection } from './config/database';
import { sendSuccess } from './utils/response.util';
import authRoutes from './modules/auth/auth.routes';
import notesRoutes from './modules/notes/notes.routes';
import { apiRateLimiter } from './middleware/rate-limit.middleware';
import { notFoundMiddleware } from './middleware/not-found.middleware';
import { errorMiddleware } from './middleware/error.middleware';

const app: Application = express();

// Sembunyikan header X-Powered-By
app.disable('x-powered-by');

// 1. Security HTTP Headers
app.use(helmet());

// 2. Cross-Origin Resource Sharing (CORS)
app.use(
  cors({
    origin: env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(','),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// 3. HTTP Request Logging (tanpa mencatat Authorization header maupun password)
if (env.NODE_ENV !== 'test') {
  app.use(morgan(':method :url :status :response-time ms - :res[content-length]'));
}

// 4. Body Parser dengan pembatasan ukuran payload (mencegah payload terlalu besar)
app.use(express.json({ limit: '100kb' }));
app.use(express.urlencoded({ extended: true, limit: '100kb' }));

// 5. General API Rate Limiting
app.use('/api', apiRateLimiter);

// 6. Health Check Endpoint (termasuk pemeriksaan status koneksi database)
app.get('/api/health', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const dbConnected = await testDatabaseConnection();
    sendSuccess(res, 'MyNotes API is running', {
      status: 'healthy',
      database: dbConnected ? 'connected' : 'disconnected',
    });
  } catch (error) {
    next(error);
  }
});

// 7. Module Routes
app.use('/api/auth', authRoutes);
app.use('/api/notes', notesRoutes);

// 8. 404 Not Found Handler
app.use(notFoundMiddleware);

// 9. Centralized Error Handler
app.use(errorMiddleware);

export default app;
