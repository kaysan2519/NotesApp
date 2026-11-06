import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import { env } from './config/env';
import { testDatabaseConnection } from './config/database';
import { sendSuccess } from './utils/response.util';
import authRoutes from './modules/auth/auth.routes';
import notesRoutes from './modules/notes/notes.routes';
import { notFoundMiddleware } from './middleware/not-found.middleware';
import { errorMiddleware } from './middleware/error.middleware';

const app: Application = express();

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

// 3. HTTP Request Logging (non-test environment)
if (env.NODE_ENV !== 'test') {
  app.use(morgan(env.NODE_ENV === 'development' ? 'dev' : 'combined'));
}

// 4. Body Parser dengan pembatasan ukuran payload (mencegah payload besar)
app.use(express.json({ limit: '100kb' }));
app.use(express.urlencoded({ extended: true, limit: '100kb' }));

// 5. Health Check Endpoint (termasuk pemeriksaan status koneksi database)
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

// 6. Module Routes
app.use('/api/auth', authRoutes);
app.use('/api/notes', notesRoutes);

// 7. 404 Not Found Handler
app.use(notFoundMiddleware);

// 8. Centralized Error Handler
app.use(errorMiddleware);

export default app;
