import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/note_model.dart';
import '../../widgets/color_picker_bar.dart';

/// Bottom sheet Note Settings sesuai referensi desain MyNotes.
/// Mengatur warna kartu, status Pin, status Private, dan aksi Delete Note.
class NoteSettingsSheet extends StatelessWidget {
  final NoteModel note;
  final ValueChanged<String> onColorChanged;
  final VoidCallback onTogglePin;
  final VoidCallback onTogglePrivacy;
  final VoidCallback onDeleteRequested;

  const NoteSettingsSheet({
    super.key,
    required this.note,
    required this.onColorChanged,
    required this.onTogglePin,
    required this.onTogglePrivacy,
    required this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Note Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fromHex(note.color),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.darkButton),
                  ),
                  child: Text(
                    AppColors.nameFromHex(note.color),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Note Color',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ColorPickerBar(
              selectedHex: note.color,
              onColorSelected: onColorChanged,
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: note.isPinned,
                    activeThumbColor: AppColors.darkButton,
                    activeTrackColor: AppColors.mintGreen,
                    onChanged: (_) => onTogglePin(),
                    secondary: const Icon(
                      Icons.push_pin_outlined,
                      color: AppColors.textPrimary,
                    ),
                    title: const Text(
                      'Pin Note to Top',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Tampilkan catatan ini di urutan paling atas',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  SwitchListTile(
                    value: note.isPrivate,
                    activeThumbColor: AppColors.darkButton,
                    activeTrackColor: AppColors.mintGreen,
                    onChanged: (_) => onTogglePrivacy(),
                    secondary: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textPrimary,
                    ),
                    title: const Text(
                      'Private Note',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Tandai sebagai catatan pribadi milik Anda',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDeleteRequested,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Delete Note',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.error, width: 1.4),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
