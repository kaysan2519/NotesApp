import http from 'http';
import app from './app';
import { env } from './config/env';

const server: http.Server = app.listen(env.PORT, () => {
  console.log(
    `[SERVER] MyNotes API running in ${env.NODE_ENV} mode on http://localhost:${env.PORT}`
  );
});

/**
 * Menangani graceful shutdown ketika proses menerima sinyal penghentian.
 */
function gracefulShutdown(signal: string): void {
  console.log(`\n[SERVER] Received ${signal}. Closing HTTP server gracefully...`);
  server.close((err) => {
    if (err) {
      console.error('[SERVER] Error during server shutdown:', err);
      process.exit(1);
    }
    console.log('[SERVER] HTTP server closed cleanly.');
    process.exit(0);
  });
}

process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
