import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pastel_background.dart';
import '../../widgets/pill_button.dart';

/// Halaman Login pengguna dengan email dan password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  void _showApiUrlDialog() {
    final urlController = TextEditingController(text: ApiConfig.baseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Konfigurasi Base URL API',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan http://10.0.2.2:3000/api untuk Android Emulator atau http://IP_LAPTOP:3000/api untuk HP fisik.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:3000/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApiConfig.setCustomBaseUrl(null);
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiConfig.setCustomBaseUrl(urlController.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintGreen,
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
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: AppColors.darkButton,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'MyNotes App',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkButton,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _showApiUrlDialog,
                            tooltip: 'Pengaturan Server API',
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Welcome back\nto MyNotes',
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
                        'Masuk untuk mengakses dan mengelola seluruh catatan pribadi Anda.',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                              controller: _emailController,
                              label: 'Email Address',
                              hintText: 'jessica@example.com',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: 'Masukkan password Anda',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validatePassword,
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 26),
                            PillButton(
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              isLoading: authState.isSubmitting,
                              onPressed: _handleLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).clearError();
                            context.go('/register');
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: 'Belum memiliki akun? ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Daftar Sekarang',
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
