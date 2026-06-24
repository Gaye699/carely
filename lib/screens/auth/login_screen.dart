import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void dispose() {
    // CORRECTION : Utilisation des bons noms de variables des contrôleurs
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final success = await auth.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mounted) setState(() => _loading = false);
      if (success && mounted) {
        final role = auth.currentUser?['role'];
        context.go(role == 'doctor' ? '/doctor' : '/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Barre du haut : Bouton retour (comme sur ton mockup) + Toggle Dark Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Consumer<ThemeProvider>(
                      builder: (_, tp, _) => IconButton(
                        icon: Icon(
                          tp.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: tp.toggle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Logo de l'application
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_hospital,
                          color: AppColors.primary,
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre principal
                Text(
                  'Bienvenue\nsur Carely',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez vos identifiants pour continuer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 36),

                // Champ Adresse e-mail
                _label('Adresse e-mail', theme, isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ Mot de passe
                _label('Mot de passe', theme, isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  // CORRECTION : Appel de la bonne méthode de soumission
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remember me + Forgot Password
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _rememberMe
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _rememberMe
                                    ? AppColors.primary
                                    : isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                width: 1.5,
                              ),
                            ),
                            child: _rememberMe
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 13,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Se souvenir de moi',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Logique mot de passe oublié
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Affichage dynamique des erreurs provenant de l'AuthService
                Consumer<AuthService>(
                  builder: (_, auth, _) => auth.error != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Bouton de connexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // CORRECTION : Appel de la bonne méthode
                    onPressed: _loading ? null : _handleLogin,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 28),

                // Séparateur "Ou"
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou continuer avec',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Boutons d'authentification sociale
                Row(
                  children: [
                    Expanded(
                      child: _socialBtn(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Google',
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _socialBtn(
                        icon: Icons.facebook_rounded,
                        label: 'Facebook',
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Lien vers la création de compte
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pas encore de compte ? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, ThemeData theme, bool isDark) => Text(
    text,
    style: theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    ),
  );

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) => OutlinedButton.icon(
    onPressed: () {},
    style: OutlinedButton.styleFrom(
      foregroundColor: isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight,
      side: BorderSide(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
      minimumSize: const Size(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
    ),
    icon: Icon(icon, color: AppColors.primary, size: 22),
    label: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}
