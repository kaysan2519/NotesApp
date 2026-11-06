import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/pill_button.dart';

/// Bottom sheet Profil Pengguna & Logout.
class ProfileSheet extends ConsumerWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final notesCount = ref.watch(notesProvider).notes.length;
    final initial = (user != null && user.username.isNotEmpty)
        ? user.username[0].toUpperCase()
        : 'U';

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
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkButton, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkButton,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.username ?? 'MyNotes User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Total Catatan Tersimpan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$notesCount Notes',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'API: ${ApiConfig.baseUrl}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            PillButton(
              label: 'Logout dari Akun',
              icon: Icons.logout_rounded,
              backgroundColor: AppColors.darkButton,
              onPressed: () async {
                Navigator.of(context).pop();
                ref.read(notesProvider.notifier).clearState();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
