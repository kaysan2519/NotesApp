import http from 'http';
import app from './app';
import { env } from './config/env';
import { testDatabaseConnection, closeDatabasePool } from './config/database';

async function bootstrap(): Promise<void> {
  const dbReady = await testDatabaseConnection();
  if (dbReady) {
    console.log(`[DATABASE] Connected to MySQL database "${env.DB_NAME}" at ${env.DB_HOST}:${env.DB_PORT}`);
  } else {
    console.warn(`[DATABASE] Warning: Could not connect to MySQL database "${env.DB_NAME}". Ensure MySQL is running and migrations have been executed.`);
  }

  const server: http.Server = app.listen(env.PORT, () => {
    console.log(
      `[SERVER] MyNotes API running in ${env.NODE_ENV} mode on http://localhost:${env.PORT}`
    );
  });

  /**
   * Menangani graceful shutdown ketika proses menerima sinyal penghentian.
   */
  function gracefulShutdown(signal: string): void {
    console.log(`\n[SERVER] Received ${signal}. Closing HTTP server and database pool...`);
    server.close(async (err) => {
      if (err) {
        console.error('[SERVER] Error during server shutdown:', err);
        process.exit(1);
      }
      try {
        await closeDatabasePool();
        console.log('[DATABASE] MySQL connection pool closed.');
      } catch (dbErr) {
        console.error('[DATABASE] Error closing MySQL pool:', dbErr);
      }
      console.log('[SERVER] HTTP server closed cleanly.');
      process.exit(0);
    });
  }

  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
}

void bootstrap();
