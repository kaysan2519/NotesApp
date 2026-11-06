import { Response } from 'express';

export interface ApiResponse<T = unknown> {
  success: boolean;
  message: string;
  data: T | null;
}

/**
 * Custom operational error class with HTTP status code.
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode = 400, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Mengirimkan response JSON sukses yang konsisten.
 */
export function sendSuccess<T>(
  res: Response,
  message: string,
  data: T | null = null,
  statusCode = 200
): Response<ApiResponse<T>> {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
}

/**
 * Mengirimkan response JSON error yang konsisten.
 */
export function sendError<T = null>(
  res: Response,
  message: string,
  statusCode = 500,
  data: T | null = null
): Response<ApiResponse<T>> {
  return res.status(statusCode).json({
    success: false,
    message,
    data,
  });
}
