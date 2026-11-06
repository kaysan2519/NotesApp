import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/color_picker_bar.dart';
import '../../widgets/pastel_background.dart';
import '../../widgets/pill_button.dart';

/// Halaman Create Note (`noteId == null`) dan Edit Note (`noteId != null`).
class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;

  const NoteEditorScreen({
    super.key,
    this.noteId,
  });

  bool get isEditMode => noteId != null;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedColorHex = AppColors.defaultNoteHex;
  bool _isPinned = false;
  bool _isPrivate = true;
  bool _isInitialLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      Future.microtask(_loadExistingNote);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    setState(() {
      _isInitialLoading = true;
    });

    final id = widget.noteId!;
    final cached =
        ref.read(notesProvider).notes.where((n) => n.id == id).firstOrNull;

    final note =
        cached ?? await ref.read(notesProvider.notifier).fetchNoteDetail(id);

    if (!mounted) return;
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      setState(() {
        _selectedColorHex = note.color;
        _isPinned = note.isPinned;
        _isPrivate = note.isPrivate;
        _isInitialLoading = false;
      });
    } else {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(notesProvider.notifier);

    if (widget.isEditMode) {
      final updated = await notifier.updateNote(
        id: widget.noteId!,
        title: _titleController.text.trim(),
        content: _contentController.text,
        color: _selectedColorHex,
        isPinned: _isPinned,
        isPrivate: _isPrivate,
      );

      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan berhasil diperbarui')),
        );
        context.pop();
      }
    } else {
      final created = await notifier.createNote(
        title: _titleController.text.trim(),
        content: _contentController.text,
        color: _selectedColorHex,
        isPinned: _isPinned,
        isPrivate: _isPrivate,
      );

      if (created != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan baru berhasil disimpan')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final previewColor = AppColors.fromHex(_selectedColorHex);

    if (_isInitialLoading) {
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

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 19,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.isEditMode ? 'Edit Note' : 'Create New Note',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notesState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.pink.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    notesState.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Color Picker Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Card Color',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              AppColors.nameFromHex(_selectedColorHex),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ColorPickerBar(
                          selectedHex: _selectedColorHex,
                          onColorSelected: (hex) {
                            setState(() {
                              _selectedColorHex = hex;
                            });
                          },
                        ),
                        const SizedBox(height: 18),

                        // Quick Pin & Privacy Toggles
                        Row(
                          children: [
                            Expanded(
                              child: _SettingToggleTile(
                                icon: _isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                label: 'Pin Note',
                                isActive: _isPinned,
                                onTap: () {
                                  setState(() {
                                    _isPinned = !_isPinned;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SettingToggleTile(
                                icon: _isPrivate
                                    ? Icons.lock_outline_rounded
                                    : Icons.lock_open_rounded,
                                label: 'Private Note',
                                isActive: _isPrivate,
                                onTap: () {
                                  setState(() {
                                    _isPrivate = !_isPrivate;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Note Editor Card Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: previewColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.darkButton.withValues(alpha: 0.14),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.darkButton.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _titleController,
                                validator: Validators.validateNoteTitle,
                                maxLength: 150,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Note Title...',
                                  counterText: '',
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.38,
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 24,
                                color: Color(0x22000000),
                              ),
                              TextFormField(
                                controller: _contentController,
                                minLines: 9,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.88,
                                  ),
                                  height: 1.55,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Tulis isi catatan, ide, atau agenda Anda di sini...',
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.42,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Save Note Pill Button
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: PillButton(
                  label: widget.isEditMode ? 'Save Changes' : 'Save Note',
                  icon: Icons.check_rounded,
                  isLoading: notesState.isSaving,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SettingToggleTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkButton : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? AppColors.darkButton : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isActive ? AppColors.mintGreen : AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
