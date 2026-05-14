import 'package:flutter/material.dart';

class Palette {
  // Legacy (kept for backward compatibility)
  static const Color firebaseNavy = Color(0xFF2C384A);
  static const Color firebaseOrange = Color(0xFFF57C00);
  static const Color firebaseAmber = Color(0xFFFFA000);
  static const Color firebaseYellow = Color(0xFFFFCA28);
  static const Color firebaseGrey = Color(0xFFECEFF1);
  static const Color googleBackground = Color(0xFF4285F4);
  static const Color maroonColor = Color(0xFF800000);

  // Brand Colors
  static const Color primaryColor = Color(0xFF144178);
  static const Color primaryLight = Color(0xFF1E5BA8);
  static const Color primaryDark = Color(0xFF0D2D54);
  static const Color secondaryColor = Color(0xFF92C83E);
  static const Color secondaryLight = Color(0xFFABDB5A);
  static const Color secondaryDark = Color(0xFF6FA02E);

  // Accent
  static const Color accentColor = Color(0xFFF5A623);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Neutrals
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Gradient presets
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
    const primary = Palette.primaryColor;
    const secondary = Palette.secondaryColor;

    return ThemeData(
      useMaterial3: false,
      primaryColor: primary,
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
      scaffoldBackgroundColor: Palette.backgroundLight,

      // AppBar
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

      // Card
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Color(0x14144178),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Palette.surface,
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surfaceVariant,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Palette.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Palette.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Palette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Palette.errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Palette.errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: Palette.textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: Palette.textDisabled, fontSize: 14),
        prefixIconColor: Palette.primaryColor,
        suffixIconColor: Palette.textSecondary,
        errorStyle: TextStyle(color: Palette.errorColor, fontSize: 12),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.primaryColor,
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.primaryColor,
          side: BorderSide(color: Palette.primaryColor, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: Palette.surface,
        elevation: 8,
        width: 285,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Palette.border,
        thickness: 1,
        space: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Palette.secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Palette.textPrimary),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Palette.textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.textPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Palette.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Palette.textSecondary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Palette.textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Palette.textPrimary, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Palette.textSecondary, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Palette.textSecondary),
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
