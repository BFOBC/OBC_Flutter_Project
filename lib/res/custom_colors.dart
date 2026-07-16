import 'package:flutter/material.dart';

class Palette {
  // ── Legacy Firebase palette (kept for compatibility) ───────────────────────
  static const Color firebaseNavy   = Color(0xFF2C384A);
  static const Color firebaseOrange = Color(0xFFF57C00);
  static const Color firebaseAmber  = Color(0xFFFFA000);
  static const Color firebaseYellow = Color(0xFFFFCA28);
  static const Color firebaseGrey   = Color(0xFFECEFF1);
  static const Color googleBackground = Color(0xFF4285F4);

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF144178); // Navy blue  (main brand)
  static const Color primaryDark    = Color(0xFF0D2D55); // Darker navy
  static const Color primaryLight   = Color(0xFF1F5BA8); // Lighter navy
  static const Color secondaryColor = Color(0xFF92C83E); // Green accent
  static const Color accentColor    = Color(0xFFF5A623); // Amber / highlight
  static const Color maroonColor    = Color(0xFF800000);

  // ── Semantic colours ───────────────────────────────────────────────────────
  static const Color success    = Color(0xFF10B981); // Emerald green
  static const Color warning    = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color info       = Color(0xFF3B82F6); // Blue

  // ── Neutral surfaces ───────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF1F5F9);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled  = Color(0xFFCBD5E1);

  // ── Borders ────────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryColor],
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: false,
      primaryColor: Palette.primaryColor,
      scaffoldBackgroundColor: Palette.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: Palette.primaryColor,
        secondary: Palette.secondaryColor,
        surface: Palette.surface,
        error: Palette.errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.primaryColor, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Palette.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: Palette.border, thickness: 1),
    );
  }
}
