import { Router } from 'express';
import { authController } from './auth.controller';
import { validate } from '../../middleware/validate.middleware';
import { authMiddleware } from '../../middleware/auth.middleware';
import { loginSchema, registerSchema } from './auth.validation';

const router = Router();

// POST /api/auth/register
router.post(
  '/register',
  validate(registerSchema, 'body'),
  (req, res, next) => authController.register(req, res, next)
);

// POST /api/auth/login
router.post(
  '/login',
  validate(loginSchema, 'body'),
  (req, res, next) => authController.login(req, res, next)
);

// GET /api/auth/me
router.get(
  '/me',
  authMiddleware,
  (req, res, next) => authController.getCurrentUser(req, res, next)
);

export default router;
