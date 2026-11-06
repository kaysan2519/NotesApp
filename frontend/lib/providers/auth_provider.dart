import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/api_exception.dart';
import '../models/user_model.dart';
import '../services/api/auth_api_service.dart';
import '../services/api/dio_client.dart';
import '../services/storage/token_storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final bool isSubmitting;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthApiService authApiService;
  final ITokenStorage tokenStorage;

  AuthNotifier({
    required this.authApiService,
    required this.tokenStorage,
    DioClient? dioClient,
  }) : super(const AuthState()) {
    dioClient?.setUnauthorizedCallback(() async {
      await handleSessionExpired();
    });
  }

  /// Memeriksa ketersediaan dan validitas JWT saat aplikasi pertama kali dibuka (Auto-Login).
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final token = await tokenStorage.getToken();
      if (token == null || token.trim().isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final currentUser = await authApiService.getCurrentUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
    } on ApiException catch (e) {
      await tokenStorage.deleteToken();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.isUnauthorized
            ? 'Sesi Anda telah berakhir. Silakan login kembali.'
            : null,
      );
    } catch (_) {
      await tokenStorage.deleteToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Melakukan login menggunakan email dan password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await authApiService.login(
        email: email,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Terjadi kesalahan saat mencoba login.',
      );
      return false;
    }
  }

  /// Melakukan registrasi akun pengguna baru.
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await authApiService.register(
        username: username,
        email: email,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Terjadi kesalahan saat mendaftarkan akun.',
      );
      return false;
    }
  }

  /// Menghapus token JWT dari penyimpanan lokal dan mereset state autentikasi.
  Future<void> logout() async {
    await authApiService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Dipanggil otomatis apabila request API mengembalikan HTTP 401.
  Future<void> handleSessionExpired() async {
    await tokenStorage.deleteToken();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Sesi login telah berakhir. Silakan masuk kembali.',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApiService = ref.watch(authApiServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dioClient = ref.watch(dioClientProvider);

  return AuthNotifier(
    authApiService: authApiService,
    tokenStorage: tokenStorage,
    dioClient: dioClient,
  );
});
