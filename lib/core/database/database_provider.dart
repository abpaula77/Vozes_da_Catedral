import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Global provider for the local SQLite database.
/// The database is a singleton throughout the app lifecycle.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
