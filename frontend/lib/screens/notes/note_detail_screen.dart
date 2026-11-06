import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/pastel_background.dart';
import '../../widgets/pill_button.dart';
import 'note_settings_sheet.dart';

/// Halaman Detail Catatan (`GET /api/notes/:id`) beserta aksi Pin, Privacy, Color, Edit, dan Delete.
class NoteDetailScreen extends ConsumerStatefulWidget {
  final int noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  NoteModel? _note;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadNoteDetail);
  }

  Future<void> _loadNoteDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Cek dari cache state terlebih dahulu untuk responsivitas instan, lalu sinkronkan dari API
    final cached = ref
        .read(notesProvider)
        .notes
        .where((n) => n.id == widget.noteId)
        .firstOrNull;
    if (cached != null && mounted) {
      setState(() {
        _note = cached;
      });
    }

    final fresh = await ref
        .read(notesProvider.notifier)
        .fetchNoteDetail(widget.noteId);

    if (!mounted) return;
    if (fresh != null) {
      setState(() {
        _note = fresh;
        _isLoading = false;
      });
    } else if (_note == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            ref.read(notesProvider).errorMessage ?? 'Catatan tidak ditemukan.';
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTogglePin() async {
    final current = _note;
    if (current == null) return;

    final updated = await ref.read(notesProvider.notifier).togglePin(current);
    if (updated != null && mounted) {
      setState(() {
        _note = updated;
      });
    }
  }

  Future<void> _handleTogglePrivacy() async {
    final current = _note;
    if (current == null) return;

    final updated =
        await ref.read(notesProvider.notifier).togglePrivacy(current);
    if (updated != null && mounted) {
      setState(() {
        _note = updated;
      });
    }
  }

  Future<void> _handleColorChange(String newHex) async {
    final current = _note;
    if (current == null) return;

    final updated = await ref.read(notesProvider.notifier).updateNote(
          id: current.id,
          title: current.title,
          content: current.content,
          color: newHex,
          isPinned: current.isPinned,
          isPrivate: current.isPrivate,
        );
    if (updated != null && mounted) {
      setState(() {
        _note = updated;
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final current = _note;
    if (current == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Catatan Ini?',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Catatan "${current.title}" akan dihapus secara permanen dari database MySQL dan tidak dapat dikembalikan.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deleted =
        await ref.read(notesProvider.notifier).deleteNote(current.id);
    if (deleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil dihapus')),
      );
      context.go('/home');
    }
  }

  void _openSettingsSheet() {
    if (_note == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentNote = _note!;
          return NoteSettingsSheet(
            note: currentNote,
            onColorChanged: (hex) async {
              await _handleColorChange(hex);
              setSheetState(() {});
            },
            onTogglePin: () async {
              await _handleTogglePin();
              setSheetState(() {});
            },
            onTogglePrivacy: () async {
              await _handleTogglePrivacy();
              setSheetState(() {});
            },
            onDeleteRequested: () {
              Navigator.of(sheetCtx).pop();
              _confirmAndDelete();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _note == null) {
      return const Scaffold(
        body: PastelBackground(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkButton),
            ),
          ),
        ),
      );
    }

    if (_note == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: PastelBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sentiment_dissatisfied_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage ?? 'Catatan tidak ditemukan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PillButton(
                    label: 'Kembali ke My Notes',
                    isFullWidth: false,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final note = _note!;
    final cardColor = AppColors.fromHex(note.color);

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation & Action Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Kembali',
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    _CircleIconButton(
                      icon: note.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      tooltip: note.isPinned ? 'Unpin Note' : 'Pin Note',
                      isActive: note.isPinned,
                      onTap: _handleTogglePin,
                    ),
                    const SizedBox(width: 10),
                    _CircleIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Note Settings',
                      onTap: _openSettingsSheet,
                    ),
                    const SizedBox(width: 10),
                    _CircleIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete Note',
                      iconColor: AppColors.error,
                      onTap: _confirmAndDelete,
                    ),
                  ],
                ),
              ),

              // Main Note Card Container
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 380),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.darkButton.withValues(alpha: 0.12),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkButton.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (note.isPinned)
                              _StatusBadge(
                                icon: Icons.push_pin_rounded,
                                label: 'Pinned',
                                isDark: true,
                              ),
                            _StatusBadge(
                              icon: note.isPrivate
                                  ? Icons.lock_outline_rounded
                                  : Icons.lock_open_rounded,
                              label: note.isPrivate ? 'Private' : 'Standard',
                            ),
                            _StatusBadge(
                              icon: Icons.palette_outlined,
                              label: AppColors.nameFromHex(note.color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SelectableText(
                          note.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.6,
                            height: 1.22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Diperbarui ${DateFormatter.formatDetailDate(note.updatedAt)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(
                            height: 1,
                            color: Color(0x22000000),
                          ),
                        ),
                        SelectableText(
                          note.content.trim().isEmpty
                              ? 'Tidak ada isi catatan tambahan.'
                              : note.content,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.88),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Action Bar (Edit Note & Note Settings)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'Edit Note',
                        icon: Icons.edit_outlined,
                        onPressed: () async {
                          await context.push('/notes/${note.id}/edit');
                          if (mounted) {
                            await _loadNoteDetail();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppColors.darkButton : AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.darkButton : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkButton.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ??
                (isActive ? AppColors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatusBadge({
    required this.icon,
    required this.label,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkButton
            : AppColors.darkButton.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? AppColors.mintGreen : AppColors.textPrimary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
