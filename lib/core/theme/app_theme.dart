import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart'; // [cite: 25]

class AppTheme {
  AppTheme._(); // [cite: 25]

  // ── LIGHT ────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true, // [cite: 26]
    brightness: Brightness.light, // [cite: 26]
    scaffoldBackgroundColor: AppColors.bgLight, // [cite: 26]
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, // [cite: 26]
      surface: AppColors.surfaceLight, // [cite: 26]
      error: AppColors.error, // [cite: 26]
      onPrimary: Colors.white, // [cite: 26]
      onSurface: AppColors.textPrimaryLight, // [cite: 26]
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgLight, // [cite: 26]
      elevation: 0, // [cite: 26]
      scrolledUnderElevation: 0, // [cite: 26]
      systemOverlayStyle: SystemUiOverlayStyle(
        // [cite: 27]
        statusBarColor: Colors.transparent, // [cite: 27]
        statusBarIconBrightness: Brightness.dark, // [cite: 27]
      ),
      titleTextStyle: TextStyle(
        // [cite: 27]
        color: AppColors.textPrimaryLight, // [cite: 27]
        fontSize: 18, // [cite: 27]
        fontWeight: FontWeight.w600, // [cite: 27]
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryLight), // [cite: 27]
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // [cite: 28]
        foregroundColor: Colors.white, // [cite: 28]
        elevation: 0, // [cite: 28]
        minimumSize: const Size(
          double.infinity,
          56,
        ), // Hauteur confortable conforme au design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ), // Plus arrondi
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ), // [cite: 28]
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(
          color: AppColors.borderLight,
        ), // Bordure grise comme la capture
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ), // Plus arrondi
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary, // [cite: 29]
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ), // [cite: 29]
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, // [cite: 29]
      fillColor: AppColors.inputFillLight, // [cite: 29]
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ), // Ajusté [cite: 29, 30]
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          24,
        ), // Entièrement arrondi comme sur l'UI
        borderSide: BorderSide.none, // [cite: 30]
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide
            .none, // Pas de bordure par défaut, juste le fond gris clair
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ), // [cite: 30]
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24), // [cite: 31]
        borderSide: const BorderSide(color: AppColors.error), // [cite: 31]
      ),
      hintStyle: const TextStyle(
        color: AppColors.textHintLight,
        fontSize: 14,
      ), // [cite: 31]
      prefixIconColor: AppColors.grey, // [cite: 31]
      suffixIconColor: AppColors.grey, // [cite: 31]
    ),
    cardTheme: CardTheme(
      elevation: 0, // [cite: 31]
      color: AppColors.cardLight, // [cite: 31]
      surfaceTintColor: Colors.transparent, // [cite: 31]
      shape: RoundedRectangleBorder(
        // [cite: 31]
        borderRadius: BorderRadius.circular(24), // [cite: 32]
        side: const BorderSide(color: AppColors.borderLight), // [cite: 32]
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight, // [cite: 32]
      selectedItemColor: AppColors.primary, // [cite: 32]
      unselectedItemColor: AppColors.greyLight, // [cite: 32]
      type: BottomNavigationBarType.fixed, // [cite: 32]
      elevation: 0, // [cite: 32]
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight, // [cite: 32]
      thickness: 0.5, // [cite: 32]
      space: 0, // [cite: 32]
    ),
  );

  // ── DARK ─────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true, // [cite: 33]
    brightness: Brightness.dark, // [cite: 33]
    scaffoldBackgroundColor: AppColors.bgDark, // [cite: 33]
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary, // [cite: 33]
      surface: AppColors.surfaceDark, // [cite: 33]
      error: AppColors.error, // [cite: 33]
      onPrimary: Colors.white, // [cite: 33]
      onSurface: AppColors.textPrimaryDark, // [cite: 33]
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark, // [cite: 34]
      elevation: 0, // [cite: 34]
      scrolledUnderElevation: 0, // [cite: 34]
      systemOverlayStyle: SystemUiOverlayStyle(
        // [cite: 34]
        statusBarColor: Colors.transparent, // [cite: 34]
        statusBarIconBrightness: Brightness.light, // [cite: 34]
      ),
      titleTextStyle: TextStyle(
        // [cite: 34]
        color: AppColors.textPrimaryDark, // [cite: 34]
        fontSize: 18, // [cite: 34]
        fontWeight: FontWeight.w600, // [cite: 34]
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark), // [cite: 34]
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // [cite: 35]
        foregroundColor: Colors.white, // [cite: 35]
        elevation: 0, // [cite: 35]
        minimumSize: const Size(double.infinity, 56), // [cite: 35]
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ), // [cite: 35]
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ), // [cite: 35]
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        side: const BorderSide(color: AppColors.borderDark),
        minimumSize: const Size(double.infinity, 56), // [cite: 36]
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ), // [cite: 36]
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(
          0xFF6095F0,
        ), // Bleu légèrement plus clair pour lisibilité [cite: 36]
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ), // [cite: 36]
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, // [cite: 36]
      fillColor: AppColors.inputFillDark, // [cite: 36]
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ), // [cite: 37]
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24), // [cite: 37]
        borderSide: BorderSide.none, // [cite: 37]
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24), // [cite: 37]
        borderSide: BorderSide.none, // [cite: 37]
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24), // [cite: 37]
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ), // [cite: 37]
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24), // [cite: 38]
        borderSide: const BorderSide(color: AppColors.error), // [cite: 38]
      ),
      hintStyle: const TextStyle(
        color: AppColors.textHintDark,
        fontSize: 14,
      ), // [cite: 38]
      prefixIconColor: AppColors.textSecondaryDark, // [cite: 38]
      suffixIconColor: AppColors.textSecondaryDark, // [cite: 38]
    ),
    cardTheme: CardTheme(
      elevation: 0, // [cite: 38]
      color: AppColors.cardDark, // [cite: 38]
      surfaceTintColor: Colors.transparent, // [cite: 38]
      shape: RoundedRectangleBorder(
        // [cite: 38]
        borderRadius: BorderRadius.circular(24), // [cite: 39]
        side: const BorderSide(color: AppColors.borderDark), // [cite: 39]
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark, // [cite: 39]
      selectedItemColor: AppColors.primary, // [cite: 39]
      unselectedItemColor: AppColors.textSecondaryDark, // [cite: 39]
      type: BottomNavigationBarType.fixed, // [cite: 39]
      elevation: 0, // [cite: 39]
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark, // [cite: 39]
      thickness: 0.5, // [cite: 39]
      space: 0, // [cite: 39]
    ),
  );
}
