import { RowDataPacket } from 'mysql2/promise';

export interface NoteRow extends RowDataPacket {
  id: number;
  user_id: number;
  title: string;
  content: string | null;
  color: string;
  is_pinned: number | boolean;
  is_private: number | boolean;
  created_at: Date;
  updated_at: Date;
}

export interface NoteItem {
  id: number;
  user_id: number;
  title: string;
  content: string;
  color: string;
  is_pinned: boolean;
  is_private: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface CreateNoteInput {
  title: string;
  content: string;
  color: string;
  is_pinned: boolean;
  is_private: boolean;
}

export interface UpdateNoteInput {
  title?: string;
  content?: string;
  color?: string;
  is_pinned?: boolean;
  is_private?: boolean;
}

export interface PinNoteInput {
  is_pinned: boolean;
}

export interface PrivacyNoteInput {
  is_private: boolean;
}

export interface NotesQueryFilter {
  search?: string;
  color?: string;
  is_pinned?: boolean;
}
