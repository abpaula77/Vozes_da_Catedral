import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_model.dart';

/// Supabase client singleton
final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Current Supabase Auth session — null when logged out
final authSessionProvider = StreamProvider<Session?>((ref) {
  return ref
      .watch(supabaseProvider)
      .auth
      .onAuthStateChange
      .map((e) => e.session);
});

/// Whether the user is currently authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.valueOrNull != null;
});

/// Current user ID (null when logged out)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser?.id;
});

/// Current user profile fetched from Supabase `users` table
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final data =
      await supabase.from('users').select().eq('id', userId).maybeSingle();

  if (data == null) return null;
  return UserModel.fromJson(data);
});

/// Auth service for sign-in / sign-out operations
class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String nome,
  ) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo:
          kIsWeb
              ? Uri.base.origin
              : 'io.supabase.vozesdacatedral://login-callback',
      data: {'nome': nome},
    );
    return response.session == null;
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo:
          kIsWeb
              ? Uri.base.origin
              : 'io.supabase.vozesdacatedral://login-callback/',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Create or update user profile in the `users` table
  Future<void> createOrUpdateProfile({
    required String userId,
    required String nome,
    required String email,
    String? foto,
    String papel = 'membro',
  }) async {
    await _client.from('users').upsert({
      'id': userId,
      'nome': nome,
      'email': email,
      'foto': foto,
      'papel': papel,
    });
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});
