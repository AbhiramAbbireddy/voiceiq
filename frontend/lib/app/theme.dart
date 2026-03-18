import 'package:flutter/material.dart';

ThemeData buildVoiceIqTheme() {
  const primary = Color(0xFF1A1A2E);
  const accent = Color(0xFF6C63FF);
  const background = Color(0xFFFFFFFF);
  const backgroundSecondary = Color(0xFFF8F8FC);
  const textPrimary = Color(0xFF1A1A2E);
  const textSecondary = Color(0xFF6B7280);
  const border = Color.fromRGBO(0, 0, 0, 0.08);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    secondary: accent,
    surface: background,
    onSurface: textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.24,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9CA3AF),
      ),
    ),
    cardTheme: CardThemeData(
      color: background,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.4),
      ),
      floatingLabelStyle: const TextStyle(
        color: accent,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerColor: border,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

ThemeData buildVoiceIqDarkTheme() {
  const primary = Color(0xFF6C63FF);
  const accent = Color(0xFFA78BFA);
  const background = Color(0xFF0F0F1A);
  const surface = Color(0xFF171728);
  const textPrimary = Color(0xFFFFFFFF);
  const textSecondary = Color(0xFF9CA3AF);
  const border = Color.fromRGBO(255, 255, 255, 0.08);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: primary,
    secondary: accent,
    surface: surface,
    onSurface: textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: textSecondary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.24,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 14 / 11,
        color: textSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      floatingLabelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerColor: border,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
