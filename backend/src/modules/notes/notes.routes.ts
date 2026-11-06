import { Router } from 'express';
import { notesController } from './notes.controller';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validate.middleware';
import {
  createNoteSchema,
  noteIdParamSchema,
  notesQuerySchema,
  pinNoteSchema,
  privacyNoteSchema,
  updateNoteSchema,
} from './notes.validation';

const router = Router();

// Seluruh endpoint Notes wajib melalui autentikasi JWT
router.use(authMiddleware);

// POST /api/notes
router.post(
  '/',
  validate(createNoteSchema, 'body'),
  (req, res, next) => notesController.createNote(req, res, next)
);

// GET /api/notes
router.get(
  '/',
  validate(notesQuerySchema, 'query'),
  (req, res, next) => notesController.getAllNotes(req, res, next)
);

// GET /api/notes/:id
router.get(
  '/:id',
  validate(noteIdParamSchema, 'params'),
  (req, res, next) => notesController.getNoteById(req, res, next)
);

// PUT /api/notes/:id
router.put(
  '/:id',
  validate(noteIdParamSchema, 'params'),
  validate(updateNoteSchema, 'body'),
  (req, res, next) => notesController.updateNote(req, res, next)
);

// DELETE /api/notes/:id
router.delete(
  '/:id',
  validate(noteIdParamSchema, 'params'),
  (req, res, next) => notesController.deleteNote(req, res, next)
);

// PATCH /api/notes/:id/pin
router.patch(
  '/:id/pin',
  validate(noteIdParamSchema, 'params'),
  validate(pinNoteSchema, 'body'),
  (req, res, next) => notesController.updateNotePin(req, res, next)
);

// PATCH /api/notes/:id/privacy
router.patch(
  '/:id/privacy',
  validate(noteIdParamSchema, 'params'),
  validate(privacyNoteSchema, 'body'),
  (req, res, next) => notesController.updateNotePrivacy(req, res, next)
);

export default router;
