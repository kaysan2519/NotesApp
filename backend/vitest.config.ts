import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    fileParallelism: false,
    testTimeout: 20000,
    hookTimeout: 20000,
    include: ['tests/**/*.test.ts'],
    env: {
      NODE_ENV: 'test',
      DB_HOST: 'localhost',
      DB_PORT: '3306',
      DB_USER: 'root',
      DB_PASSWORD: '',
      DB_NAME: 'mynotes_test_db',
      DB_SSL: 'false',
      DB_SSL_CA_BASE64: '',
      JWT_SECRET: 'test_jwt_secret_key_mynotes_2026',
      JWT_EXPIRES_IN: '1d',
      BCRYPT_SALT_ROUNDS: '4',
    },
  },
});

