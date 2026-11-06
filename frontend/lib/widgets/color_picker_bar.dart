import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Pemilih warna kartu catatan pastel horizontal (8 warna resmi MyNotes).
class ColorPickerBar extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onColorSelected;

  const ColorPickerBar({
    super.key,
    required this.selectedHex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = selectedHex.trim().toUpperCase();

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppColors.noteColorOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = AppColors.noteColorOptions[index];
          final isSelected = option.hex == normalizedSelected;

          return Tooltip(
            message: option.name,
            child: GestureDetector(
              onTap: () => onColorSelected(option.hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.darkButton
                        : AppColors.darkButton.withValues(alpha: 0.2),
                    width: isSelected ? 2.6 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.darkButton.withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.darkButton,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
