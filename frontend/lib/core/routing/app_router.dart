import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/notes/note_detail_screen.dart';
import '../../screens/notes/note_editor_screen.dart';
import '../../screens/splash/splash_screen.dart';

/// Notifier untuk memicu evaluasi ulang redirect GoRouter ketika status autentikasi berubah.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      final isSplash = location == '/splash';
      final isAuthRoute = location == '/login' || location == '/register';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }

      if (authState.status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (authState.status == AuthStatus.authenticated &&
          (isSplash || isAuthRoute)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/notes/create',
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return NoteDetailScreen(noteId: id);
        },
      ),
      GoRoute(
        path: '/notes/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return NoteEditorScreen(noteId: id);
        },
      ),
    ],
  );
});
