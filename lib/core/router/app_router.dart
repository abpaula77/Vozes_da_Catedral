import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/presentation/group_members_screen.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/songs/presentation/song_detail_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Route path constants
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const groups = '/groups';
  static const groupDetail = '/groups/:grupoId';
  static const groupMembers = '/groups/:grupoId/members';
  static const songDetail = '/groups/:grupoId/songs/:musicaId';

  static String groupDetailPath(String grupoId) => '/groups/$grupoId';
  static String groupMembersPath(String grupoId) => '/groups/$grupoId/members';
  static String songDetailPath(String grupoId, String musicaId) =>
      '/groups/$grupoId/songs/$musicaId';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final location = state.uri.path;

      if (location == AppRoutes.splash) return null;
      if (location == AppRoutes.onboarding) return null;

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
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.groups,
        builder: (context, state) => const GroupsScreen(),
        routes: [
          GoRoute(
            path: ':grupoId',
            builder:
                (context, state) => GroupDetailScreen(
                  grupoId: state.pathParameters['grupoId']!,
                ),
            routes: [
              GoRoute(
                path: 'members',
                builder:
                    (context, state) => GroupMembersScreen(
                      grupoId: state.pathParameters['grupoId']!,
                    ),
              ),
              GoRoute(
                path: 'songs/:musicaId',
                builder:
                    (context, state) => SongDetailScreen(
                      musicaId: state.pathParameters['musicaId']!,
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Splash screen that redirects to login or home after auth check
class _SplashRedirector extends ConsumerStatefulWidget {
  const _SplashRedirector();

  @override
  ConsumerState<_SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends ConsumerState<_SplashRedirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Check if user has completed onboarding (profile exists)
        final supabase = ref.read(supabaseProvider);
        final profile =
            await supabase
                .from('users')
                .select('id')
                .eq('id', session.user.id)
                .maybeSingle();

        if (mounted) {
          if (profile == null) {
            context.go(AppRoutes.onboarding);
          } else {
            context.go(AppRoutes.groups);
          }
        }
      } else {
        if (mounted) context.go(AppRoutes.login);
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

/// Navigation extension helpers
extension AppNavigation on BuildContext {
  void goGroupDetail(String grupoId) => go(AppRoutes.groupDetailPath(grupoId));

  void pushGroupMembers(String grupoId) =>
      push(AppRoutes.groupMembersPath(grupoId));

  void pushSongDetail(String grupoId, String musicaId) =>
      push(AppRoutes.songDetailPath(grupoId, musicaId));
}
