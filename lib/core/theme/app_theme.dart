import 'package:flutter/material.dart';

/// Application theme definitions.
/// Dark theme is optimized for low-light environments (church/altar settings).
class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(
    0xFF7B3F00,
  ); // Deep brown — liturgical gold
  static const _primaryDark = Color(0xFFD4A017); // Muted gold for dark mode

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
  );

  /// Dark theme with reduced brightness for altar/performance use.
  /// Avoids pure white (#FFF) to prevent glare in dark environments.
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      // Slightly warm surface instead of pure black — easier on the eyes
      surface: const Color(0xFF1A1A1A),
      onSurface: const Color(0xFFE8E0D5),
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}
