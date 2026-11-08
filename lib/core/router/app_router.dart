import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Route path constants
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const groups = '/groups';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to trigger router refresh
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final location = state.uri.path;

      // Still on splash — let it handle navigation
      if (location == AppRoutes.splash) return null;

      if (!isLoggedIn && location != AppRoutes.login) {
        return AppRoutes.login;
      }
      if (isLoggedIn && location == AppRoutes.login) {
        return AppRoutes.groups;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashRedirector(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.groups,
        builder: (context, state) => const GroupsScreen(),
      ),
    ],
  );
});

/// Splash screen that redirects based on auth state after initialization
class _SplashRedirector extends ConsumerStatefulWidget {
  const _SplashRedirector();

  @override
  ConsumerState<_SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends ConsumerState<_SplashRedirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context.go(AppRoutes.groups);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

/// Listenable that refreshes the router when auth state changes
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authSessionProvider, (_, __) => notifyListeners());
  }
}
