import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../home/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _acceptTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez accepter les conditions d'utilisation"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.cardDark
                            : AppColors.inputFillLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    Consumer<ThemeProvider>(
                      builder: (_, tp, __) => IconButton(
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

                Text(
                  'Créer un compte',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez Carely pour gérer vos rendez-vous',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),

                _label('Nom complet', theme, isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Jean Dupont',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

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

                _label('Mot de passe', theme, isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 16),

                _label('Confirmer le mot de passe', theme, isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v != _passwordCtrl.text)
                      return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // CGU
                GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(top: 2),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _acceptTerms
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _acceptTerms
                                ? AppColors.primary
                                : isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1.5,
                          ),
                        ),
                        child: _acceptTerms
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 13,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall,
                            children: [
                              const TextSpan(text: "J'accepte les "),
                              const TextSpan(
                                text: "Conditions d'utilisation",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: " et la "),
                              const TextSpan(
                                text: "Politique de confidentialité",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 28),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Se connecter',
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
}
