/**
 * Konfigurasi terpusat untuk daftar warna kartu catatan MyNotes.
 * Jika ingin menambah atau mengubah pilihan warna catatan, cukup ubah file ini.
 */
export const NOTE_COLORS = {
  MINT_GREEN: '#A5F3AD',
  LAVENDER: '#D8A7F5',
  YELLOW: '#F6DB59',
  PINK: '#F2A3A6',
  TURQUOISE: '#70DDC7',
  BLUE: '#83BCEB',
  GRAY: '#D9D9D9',
  WHITE: '#FFFFFF',
} as const;

export const ALLOWED_NOTE_COLORS: readonly string[] = Object.values(NOTE_COLORS);

export const DEFAULT_NOTE_COLOR: string = NOTE_COLORS.MINT_GREEN;

export function isValidNoteColor(color: string): boolean {
  return ALLOWED_NOTE_COLORS.includes(color.trim().toUpperCase());
}
