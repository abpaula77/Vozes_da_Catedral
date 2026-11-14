import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_provider.dart';
import 'app_database.dart';

/// Global provider for the local SQLite database.
/// The database is a singleton throughout the app lifecycle.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Completes once the local cache belongs to the signed-in account (#61).
/// When another account signs in on the same device, the previous account's
/// cache is cleared first. Signing out keeps the cache. Readers of the local
/// database wait for this provider so they never show another account's data.
final cacheLocalProntoProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return;
  await ref.read(databaseProvider).garantirDonoDoCache(userId);
});
