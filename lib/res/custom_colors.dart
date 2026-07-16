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
  static const Color primaryDark    = Color(0xFF0D2D54); // Darker navy
  static const Color primaryLight   = Color(0xFF1E5BA8); // Lighter navy
  static const Color secondaryColor = Color(0xFF92C83E); // Green accent
  static const Color secondaryLight = Color(0xFFABDB5A);
  static const Color secondaryDark  = Color(0xFF6FA02E);
  static const Color accentColor    = Color(0xFFF5A623); // Amber / highlight
  static const Color maroonColor    = Color(0xFF800000);

  // ── Semantic colours ───────────────────────────────────────────────────────
  static const Color success    = Color(0xFF10B981);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color info       = Color(0xFF3B82F6);

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

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, primaryColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get light {
    const primary   = Palette.primaryColor;
    const secondary = Palette.secondaryColor;

    return ThemeData(
      useMaterial3: false,
      primaryColor: primary,
      scaffoldBackgroundColor: Palette.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Palette.surface,
        background: Palette.backgroundLight,
        error: Palette.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Palette.textPrimary,
        onBackground: Palette.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Palette.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: const Color(0x14144178),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Palette.surface,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Palette.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: Palette.textDisabled, fontSize: 14),
        prefixIconColor: Palette.primaryColor,
        suffixIconColor: Palette.textSecondary,
        errorStyle: const TextStyle(color: Palette.errorColor, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Palette.border, thickness: 1),
    );
  }
}
