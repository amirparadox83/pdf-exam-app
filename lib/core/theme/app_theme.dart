/// App theme — Persian RTL aware, light & dark variants
/// Stage 04 — Project Foundation
/// Stage 06 — Design System
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // === Color palette ===
  // Primary: deep indigo-blue (academic, calm)
  static const Color _primaryLight = Color(0xFF1E3A8A);
  static const Color _primaryDark = Color(0xFF3B82F6);
  // Accent: cyan
  static const Color _accentLight = Color(0xFF0EA5E9);
  static const Color _accentDark = Color(0xFF38BDF8);
  // Background
  static const Color _bgLight = Color(0xFFFAFBFC);
  static const Color _bgDark = Color(0xFF0F172A);
  // Surface
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF1E293B);
  // Text
  static const Color _textPrimaryLight = Color(0xFF0F172A);
  static const Color _textPrimaryDark = Color(0xFFF1F5F9);
  static const Color _textSecondaryLight = Color(0xFF475569);
  static const Color _textSecondaryDark = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Question states
  static const Color correctColor = Color(0xFF16A34A);
  static const Color incorrectColor = Color(0xFFDC2626);
  static const Color unansweredColor = Color(0xFF94A3B8);
  static const Color bookmarkColor = Color(0xFFF59E0B);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryLight,
      brightness: Brightness.light,
      primary: _primaryLight,
      secondary: _accentLight,
      surface: _surfaceLight,
      background: _bgLight,
      error: error,
    );

    return _buildTheme(colorScheme, _textPrimaryLight, _textSecondaryLight);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryDark,
      brightness: Brightness.dark,
      primary: _primaryDark,
      secondary: _accentDark,
      surface: _surfaceDark,
      background: _bgDark,
      error: error,
    );

    return _buildTheme(colorScheme, _textPrimaryDark, _textSecondaryDark);
  }

  static ThemeData _buildTheme(
    ColorScheme scheme,
    Color textPrimary,
    Color textSecondary,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      // Persian font family
      fontFamily: 'Vazirmatn',
      scaffoldBackgroundColor: scheme.background,
      canvasColor: scheme.background,
      // RTL default
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          color: textPrimary,
        ),
        side: BorderSide(color: scheme.outline.withOpacity(0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );

    return base;
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Vazirmatn', fontSize: 32, fontWeight: FontWeight.w700, color: primary, height: 1.3),
      displayMedium: TextStyle(fontFamily: 'Vazirmatn', fontSize: 28, fontWeight: FontWeight.w700, color: primary, height: 1.3),
      displaySmall: TextStyle(fontFamily: 'Vazirmatn', fontSize: 24, fontWeight: FontWeight.w700, color: primary, height: 1.3),
      headlineLarge: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.w700, color: primary, height: 1.4),
      headlineMedium: TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      headlineSmall: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      titleLarge: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.w700, color: primary, height: 1.5),
      titleMedium: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.w600, color: primary, height: 1.5),
      titleSmall: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.w600, color: primary, height: 1.5),
      bodyLarge: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.w400, color: primary, height: 1.7),
      bodyMedium: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.w400, color: primary, height: 1.7),
      bodySmall: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.w400, color: secondary, height: 1.6),
      labelLarge: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.w700, color: primary, height: 1.4),
      labelMedium: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      labelSmall: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, fontWeight: FontWeight.w500, color: secondary, height: 1.4),
    );
  }
}

/// App spacing tokens
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// App radii
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}
