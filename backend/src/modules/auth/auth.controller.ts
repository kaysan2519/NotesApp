import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import { LoginInput, RegisterInput } from './auth.types';
import { AppError, sendSuccess } from '../../utils/response.util';

export class AuthController {
  /**
   * POST /api/auth/register
   */
  public async register(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const input = req.body as RegisterInput;
      const result = await authService.register(input);
      sendSuccess(res, 'User registered successfully', result, 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/login
   */
  public async login(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const input = req.body as LoginInput;
      const result = await authService.login(input);
      sendSuccess(res, 'Login successful', result, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/auth/me
   */
  public async getCurrentUser(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        throw new AppError('Unauthorized', 401);
      }
      const user = await authService.getCurrentUser(req.user.id);
      sendSuccess(res, 'Current user retrieved successfully', { user }, 200);
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
