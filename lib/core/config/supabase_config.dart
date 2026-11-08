/// Supabase project configuration.
/// Replace these placeholder values with your actual Supabase project credentials
/// from your Supabase dashboard under Settings > API.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-id.supabase.co',
  );

  /// Your Supabase publishable (anon) key.
  /// This is safe to include in client-side apps.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );
}
