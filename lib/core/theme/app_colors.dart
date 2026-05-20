import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // [cite: 10]

  // Primaire (Bleu de ta nouvelle capture)
  static const Color primary = Color(0xFF3775E0);
  static const Color primaryLight = Color(0xFFF2F8FF);
  static const Color primaryDark = Color(0xFF1F5BBF);

  // Neutres
  static const Color navy = Color(0xFF9694A0); // Gris de la capture
  static const Color darkNavy = Color(
    0xFF121027,
  ); // Bleu nuit/Noir de la capture
  static const Color grey = Color(0xFF9694A0);
  static const Color greyLight = Color(0xFFE0E0E0);

  // Sémantiques [cite: 14]
  static const Color success = Color(0xFF35C08A); // [cite: 14]
  static const Color error = Color(0xFFE05050); // [cite: 14]
  static const Color warning = Color(0xFFF5A623); // [cite: 15]
  static const Color star = Color(0xFFFFC107); // [cite: 15]

  // Light mode (Adapté à ton écran de login)
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color inputFillLight = Color(
    0xFFF7F7F7,
  ); // Fond des inputs gris très clair
  static const Color textPrimaryLight = Color(0xFF121027);
  static const Color textSecondaryLight = Color(0xFF9694A0);
  static const Color textHintLight = Color(0xFF9694A0);

  // Dark mode (Combinaison basée sur ton Bleu Nuit profond #121027)
  static const Color bgDark = Color(0xFF121027); // Fond principal
  static const Color surfaceDark = Color(
    0xFF1A1833,
  ); // Légèrement plus clair pour les éléments de surface
  static const Color cardDark = Color(
    0xFF222042,
  ); // Pour faire ressortir les cartes
  static const Color borderDark = Color(
    0xFF2E2C54,
  ); // Bordures subtiles en mode sombre
  static const Color inputFillDark = Color(0xFF1A1833);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9694A0);
  static const Color textHintDark = Color(0xFF6A697A);

  // Gradients mis à jour avec ton nouveau bleu
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF3775E0), Color(0xFF1F5BBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF3775E0), Color(0xFF6095F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
