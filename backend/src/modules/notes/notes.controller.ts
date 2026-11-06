import { Request, Response, NextFunction } from 'express';
import { notesService } from './notes.service';
import {
  CreateNoteInput,
  NotesQueryFilter,
  PinNoteInput,
  PrivacyNoteInput,
  UpdateNoteInput,
} from './notes.types';
import { AppError, sendSuccess } from '../../utils/response.util';

export class NotesController {
  private getUserId(req: Request): number {
    if (!req.user || typeof req.user.id !== 'number') {
      throw new AppError('Unauthorized', 401);
    }
    return req.user.id;
  }

  /**
   * POST /api/notes
   */
  public async createNote(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const input = req.body as CreateNoteInput;
      const note = await notesService.createNote(userId, input);
      sendSuccess(res, 'Note created successfully', note, 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/notes
   */
  public async getAllNotes(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const filter = req.query as unknown as NotesQueryFilter;
      const notes = await notesService.getAllNotes(userId, filter);
      sendSuccess(res, 'Notes retrieved successfully', notes, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/notes/:id
   */
  public async getNoteById(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const noteId = Number(req.params.id);
      const note = await notesService.getNoteById(userId, noteId);
      sendSuccess(res, 'Note retrieved successfully', note, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/notes/:id
   */
  public async updateNote(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const noteId = Number(req.params.id);
      const input = req.body as UpdateNoteInput;
      const note = await notesService.updateNote(userId, noteId, input);
      sendSuccess(res, 'Note updated successfully', note, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/notes/:id
   */
  public async deleteNote(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const noteId = Number(req.params.id);
      await notesService.deleteNote(userId, noteId);
      sendSuccess(res, 'Note deleted successfully', null, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/notes/:id/pin
   */
  public async updateNotePin(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const noteId = Number(req.params.id);
      const { is_pinned } = req.body as PinNoteInput;
      const note = await notesService.updateNotePin(userId, noteId, is_pinned);
      sendSuccess(res, 'Note pin status updated successfully', note, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/notes/:id/privacy
   */
  public async updateNotePrivacy(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const noteId = Number(req.params.id);
      const { is_private } = req.body as PrivacyNoteInput;
      const note = await notesService.updateNotePrivacy(userId, noteId, is_private);
      sendSuccess(res, 'Note privacy status updated successfully', note, 200);
    } catch (error) {
      next(error);
    }
  }
}

export const notesController = new NotesController();
