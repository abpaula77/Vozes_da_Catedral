/// Supabase project configuration.
///
/// Values are read from --dart-define at build time.
/// For local development, run with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// Or use the launch.json / Makefile shortcuts in this repo.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://npujroyocclobjrpeaed.supabase.co',
  );

  /// Supabase publishable (anon) key — safe for client-side use.
  /// Access is controlled server-side via Row Level Security (RLS).
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wdWpyb3lvY2Nsb2JqcnBlYWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxNjEyMTUsImV4cCI6MjEwOTczNzIxNX0.pDXIzq9IiPHGy5-sDPlVc1jfmToebSjAVmLd1lUko7o',
  );
}
