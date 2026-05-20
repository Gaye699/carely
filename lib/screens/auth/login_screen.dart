import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Palette de couleurs de la maquette
  static const Color primaryColor = Color(0xFF3775E0); // Bleu principal
  static const Color backgroundColor = Color(0xFFFFFFFF); // Blanc de fond
  static const Color inputBgColor = Color(
    0xFFF7F7F7,
  ); // Gris clair pour les champs
  static const Color textColorDark = Color(0xFF121027); // Noir/Bleu nuit
  static const Color textColorMuted = Color(
    0xFF9694A0,
  ); // Gris pour les labels et séparateurs
  static const Color dividerColor = Color(
    0xFFE0E0E0,
  ); // Gris de la ligne de séparation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton Retour (haut gauche)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: inputBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: textColorDark),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),

              // Titre Principal CENTRÉ
              const Center(
                child: Text(
                  'Connectez-vous à votre compte',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: textColorDark,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),

              // Label Email
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: textColorDark,
                ),
              ),
              const SizedBox(height: 8.0),

              // Champ Email
              TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Label Password
              const Text(
                'Mot de passe',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: textColorDark,
                ),
              ),
              const SizedBox(height: 8.0),

              // Champ Password
              TextFormField(
                obscureText: true,
                style: const TextStyle(color: textColorDark),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBgColor,
                  suffixIcon: const Icon(
                    Icons.visibility_off_outlined,
                    color: textColorMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Remember me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: Checkbox(
                          value: false,
                          onChanged: (value) {},
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          side: const BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text(
                        'Se souvenir de moi',
                        style: TextStyle(
                          color: textColorDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Mot de passe oublié',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Bouton Login
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32.0),

              // --- Petite barre grise avec "Or" ---
              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      color: dividerColor,
                      thickness: 1,
                      endIndent: 16,
                    ),
                  ),
                  Text(
                    'Ou',
                    style: TextStyle(
                      color: textColorMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: dividerColor,
                      thickness: 1,
                      indent: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Boutons Sociaux (Google & Apple en ligne)
              Row(
                children: [
                  // Bouton Google
                  Expanded(
                    child: SizedBox(
                      height: 56.0,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.g_mobiledata,
                          color: Colors.red,
                          size: 30,
                        ),
                        label: const Text(
                          'Google',
                          style: TextStyle(
                            color: textColorDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),

                  // Bouton Apple
                  Expanded(
                    child: SizedBox(
                      height: 56.0,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 24,
                        ),
                        label: const Text(
                          'Apple',
                          style: TextStyle(
                            color: textColorDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),

              // --- Section S'inscrire (Don't have an account?) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Vous n'avez pas de compte? ",
                    style: TextStyle(color: textColorMuted, fontSize: 14.0),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigation vers la page d'inscription à créer
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0), // Marge de sécurité en bas
            ],
          ),
        ),
      ),
    );
  }
}
