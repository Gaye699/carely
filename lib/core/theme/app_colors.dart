import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  //  Palette principale
  static const Color primary = Color(0xFF2177BD);
  static const Color primaryLight = Color(0xFFF2F8FF);
  static const Color primaryDark = Color(0xFF1558A0);

  // Palette secondaire
  static const Color darkNavy = Color(0xFF1F2037);
  static const Color navy = Color(0xFF454665);

  //  Neutres
  static const Color grey50 = Color(0xFFF7F8FC);
  static const Color grey100 = Color(0xFFEEF0F5);
  static const Color grey200 = Color(0xFFC7C7C7);
  static const Color grey300 = Color(0xFFC8D0D0);
  static const Color grey500 = Color(0xFFA6A6A6);
  static const Color grey700 = Color(0xFF9694A0);

  // Sémantiques
  static const Color success = Color(0xFF35C08A);
  static const Color successLight = Color(0xFFEAFAF2);
  static const Color error = Color(0xFFE05050);
  static const Color errorLight = Color(0xFFFEF0F0);
  static const Color warning = Color(0xFFF5A623);
  static const Color star = Color(0xFFFFC107);

  // Light mode
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color scaffoldLight = Color(0xFFF7F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEEF0F5);
  static const Color inputFillLight = Color(0xFFF7F8FC);
  static const Color textPrimaryLight = Color(0xFF1F2037);
  static const Color textSecondaryLight = Color(0xFF9694A0);
  static const Color textHintLight = Color(0xFFC7C7C7);

  // Dark mode
  static const Color bgDark = Color(0xFF121027);
  static const Color scaffoldDark = Color(0xFF0E0D20);
  static const Color surfaceDark = Color(0xFF1A1833);
  static const Color cardDark = Color(0xFF222042);
  static const Color borderDark = Color(0xFF2E2C54);
  static const Color inputFillDark = Color(0xFF1A1833);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9694A0);
  static const Color textHintDark = Color(0xFF6A697A);

  static const Color grey = Color(0xFF9EA6B0);
  static const Color greyLight = Color(0xFFC7C7C7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2177BD), Color(0xFF1558A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2177BD), Color(0xFF4A9FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF2177BD), Color(0xFF1558A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
