import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pastel_background.dart';
import '../../widgets/pill_button.dart';

/// Halaman Registrasi akun pengguna baru (username, email, password).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.darkButton,
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 15,
                              color: AppColors.darkButton,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Start your\nMyNotes space',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.9,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Buat akun baru untuk menyimpan seluruh ide dan catatan penting Anda.',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.darkButton.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (authState.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.pink.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.4),
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
                                        authState.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            CustomTextField(
                              controller: _usernameController,
                              label: 'Username',
                              hintText: 'jessica',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: Validators.validateUsername,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hintText: 'jessica@example.com',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: 'Minimal 6 karakter',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validatePassword,
                              onFieldSubmitted: (_) => _handleRegister(),
                            ),
                            const SizedBox(height: 24),
                            PillButton(
                              label: 'Create Account',
                              icon: Icons.check_circle_outline_rounded,
                              isLoading: authState.isSubmitting,
                              onPressed: _handleRegister,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).clearError();
                            context.go('/login');
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: 'Sudah memiliki akun? ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Masuk di sini',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
