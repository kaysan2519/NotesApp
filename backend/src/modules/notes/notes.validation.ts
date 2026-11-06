import { z } from 'zod';
import {
  ALLOWED_NOTE_COLORS,
  DEFAULT_NOTE_COLOR,
  isValidNoteColor,
} from '../../config/note-colors';

const noteColorSchema = z
  .string()
  .trim()
  .transform((val) => val.toUpperCase())
  .refine((val) => isValidNoteColor(val), {
    message: `Warna catatan tidak valid. Pilihan warna yang diizinkan: ${ALLOWED_NOTE_COLORS.join(', ')}`,
  });

export const createNoteSchema = z.object({
  title: z
    .string({ required_error: 'Judul catatan wajib diisi' })
    .trim()
    .min(1, 'Judul catatan tidak boleh kosong')
    .max(150, 'Judul catatan maksimal 150 karakter'),
  content: z
    .string()
    .max(65535, 'Isi catatan maksimal 65535 karakter')
    .optional()
    .default(''),
  color: noteColorSchema.optional().default(DEFAULT_NOTE_COLOR),
  is_pinned: z.boolean().optional().default(false),
  is_private: z.boolean().optional().default(true),
});

export const updateNoteSchema = z
  .object({
    title: z
      .string()
      .trim()
      .min(1, 'Judul catatan tidak boleh kosong')
      .max(150, 'Judul catatan maksimal 150 karakter')
      .optional(),
    content: z
      .string()
      .max(65535, 'Isi catatan maksimal 65535 karakter')
      .optional(),
    color: noteColorSchema.optional(),
    is_pinned: z.boolean().optional(),
    is_private: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Minimal satu field harus dikirimkan untuk memperbarui catatan',
  });

export const pinNoteSchema = z.object({
  is_pinned: z.boolean({
    required_error: 'Field is_pinned wajib diisi',
    invalid_type_error: 'Field is_pinned harus bertipe boolean',
  }),
});

export const privacyNoteSchema = z.object({
  is_private: z.boolean({
    required_error: 'Field is_private wajib diisi',
    invalid_type_error: 'Field is_private harus bertipe boolean',
  }),
});

export const noteIdParamSchema = z.object({
  id: z.coerce
    .number({ invalid_type_error: 'ID catatan harus berupa angka' })
    .int('ID catatan harus berupa bilangan bulat')
    .positive('ID catatan harus berupa angka positif'),
});

export const notesQuerySchema = z.object({
  search: z.string().trim().optional(),
  color: noteColorSchema.optional(),
  is_pinned: z
    .enum(['true', 'false'], {
      errorMap: () => ({ message: 'Query is_pinned harus bernilai true atau false' }),
    })
    .transform((val) => val === 'true')
    .optional(),
});
