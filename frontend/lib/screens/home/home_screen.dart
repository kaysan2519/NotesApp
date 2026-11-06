import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/pastel_background.dart';
import '../../widgets/pill_button.dart';
import 'profile_sheet.dart';

/// Halaman utama My Notes Dashboard sesuai gambar referensi desain MyNotes.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notesProvider.notifier).fetchNotes();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      ref.read(notesProvider.notifier).setSearchQuery(value);
    });
    setState(() {});
  }

  void _openProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notesState = ref.watch(notesProvider);
    final username = authState.user?.username ?? 'User';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Profile Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $username 👋',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'My Notes',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _openProfileSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkButton.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.mintGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.darkButton,
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkButton,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.more_horiz_rounded,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search your notes...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 19,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // 3. Filter Pills (All Notes & Pinned)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _FilterChipPill(
                          label: 'All Notes',
                          isSelected: !notesState.onlyPinned,
                          onTap: () => ref
                              .read(notesProvider.notifier)
                              .setOnlyPinned(false),
                        ),
                        const SizedBox(width: 10),
                        _FilterChipPill(
                          label: 'Pinned',
                          icon: Icons.push_pin_rounded,
                          isSelected: notesState.onlyPinned,
                          onTap: () => ref
                              .read(notesProvider.notifier)
                              .setOnlyPinned(true),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              ref.read(notesProvider.notifier).fetchNotes(),
                          tooltip: 'Refresh Notes',
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 21,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Notes Content (Loading / Error / Empty / Grid)
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.darkButton,
                      onRefresh: () =>
                          ref.read(notesProvider.notifier).fetchNotes(),
                      child: _buildNotesBody(context, notesState),
                    ),
                  ),
                ],
              ),

              // 5. Floating Add New Note Pill Button
              Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: PillButton(
                      label: 'Add New Note',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/notes/create'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesBody(BuildContext context, NotesState notesState) {
    if (notesState.isLoading && notesState.notes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkButton),
        ),
      );
    }

    if (notesState.errorMessage != null && notesState.notes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 46,
                  color: AppColors.error,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Gagal Memuat Catatan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notesState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: 'Coba Lagi',
                  icon: Icons.refresh_rounded,
                  isFullWidth: false,
                  onPressed: () =>
                      ref.read(notesProvider.notifier).fetchNotes(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (notesState.notes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        children: [
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkButton, width: 1.5),
              ),
              child: const Icon(
                Icons.note_add_outlined,
                size: 36,
                color: AppColors.darkButton,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            notesState.searchQuery.isNotEmpty
                ? 'Catatan Tidak Ditemukan'
                : (notesState.onlyPinned
                    ? 'Belum Ada Catatan yang Di-Pin'
                    : 'Belum Ada Catatan Pribadi'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notesState.searchQuery.isNotEmpty
                ? 'Coba gunakan kata kunci pencarian lain.'
                : 'Ketuk tombol "Add New Note" di bawah untuk membuat catatan pertama Anda.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 900
        ? 4
        : (screenWidth >= 600 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.86,
      ),
      itemCount: notesState.notes.length,
      itemBuilder: (context, index) {
        final note = notesState.notes[index];
        return NoteCard(
          note: note,
          onTap: () => context.push('/notes/${note.id}'),
          onTogglePin: () => ref.read(notesProvider.notifier).togglePin(note),
        );
      },
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkButton : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.darkButton : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.mintGreen : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
