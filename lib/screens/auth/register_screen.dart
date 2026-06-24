import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/theme_provider.dart';

const _specialties = [
  'Médecin généraliste',
  'Cardiologue',
  'Dermatologue',
  'Neurologue',
  'Pédiatre',
  'Orthopédiste',
  'Ophtalmologue',
  'Psychiatre',
  'Dentiste',
  'Gynécologue',
  'Rhumatologue',
  'Endocrinologue',
  'Gastro-entérologue',
  'Pneumologue',
  'Urologue',
];

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
  final _rppsCtrl = TextEditingController();

  String _role = 'patient';
  String? _selectedSpecialty;
  XFile? _pickedImage;
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
    _rppsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 512);
    if (file != null) setState(() => _pickedImage = file);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez accepter les conditions d'utilisation."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final nameParts = _nameCtrl.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      String? avatarBase64;
      if (_pickedImage != null) {
        final bytes = await File(_pickedImage!.path).readAsBytes();
        avatarBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final auth = context.read<AuthService>();
      final success = await auth.register(
        firstName: firstName,
        lastName: lastName,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
        specialty: _role == 'doctor' ? _selectedSpecialty : null,
        rppsNumber: _role == 'doctor' ? _rppsCtrl.text.trim() : null,
        avatarUrl: avatarBase64,
      );

      if (mounted) setState(() => _loading = false);
      if (success && mounted) {
        if (_role == 'doctor') {
          // Médecin créé mais non vérifié — montrer un message
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Compte en attente'),
              content: const Text(
                'Votre compte médecin a été créé.\n\n'
                'Votre numéro RPPS va être vérifié par notre équipe '
                '(délai : 24-48h). Vous recevrez une confirmation par email.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  child: const Text('Compris'),
                ),
              ],
            ),
          );
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.redAccent),
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.cardDark : AppColors.inputFillLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    const Spacer(),
                    Consumer<ThemeProvider>(
                      builder: (_, tp, _) => IconButton(
                        icon: Icon(
                          tp.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: tp.toggle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Créer un compte',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    )),
                const SizedBox(height: 8),
                Text('Rejoignez Carely pour gérer vos rendez-vous',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    )),
                const SizedBox(height: 28),

                // Sélection du rôle
                _label('Je suis…', theme, isDark),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleChip('patient', 'Patient', Icons.person_outline, isDark),
                    const SizedBox(width: 12),
                    _roleChip('doctor', 'Médecin', Icons.medical_services_outlined, isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // Photo de profil
                Center(
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _pickedImage != null
                              ? FileImage(File(_pickedImage!.path))
                              : null,
                          child: _pickedImage == null
                              ? Icon(Icons.person_rounded,
                                  size: 44, color: AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isDark ? AppColors.cardDark : Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Ajouter une photo',
                      style: TextStyle(fontSize: 12, color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 24),

                // Nom complet
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Email
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

                // Champs spécifiques médecin
                if (_role == 'doctor') ...[
                  _label('Spécialité', theme, isDark),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    decoration: const InputDecoration(
                      hintText: 'Sélectionner une spécialité',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                    items: _specialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSpecialty = v),
                    validator: (v) => v == null ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Numéro RPPS', theme, isDark),
                  const SizedBox(height: 4),
                  Text(
                    'Répertoire Partagé des Professionnels de Santé (11 chiffres)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _rppsCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: 11,
                    decoration: const InputDecoration(
                      hintText: '12345678901',
                      prefixIcon: Icon(Icons.badge_outlined),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (!RegExp(r'^\d{11}$').hasMatch(v.trim())) {
                        return 'Le numéro RPPS doit contenir 11 chiffres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Mot de passe
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
                      icon: Icon(_showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmation
                _label('Confirmer le mot de passe', theme, isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
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
                          color: _acceptTerms ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _acceptTerms
                                ? AppColors.primary
                                : isDark ? AppColors.borderDark : AppColors.borderLight,
                            width: 1.5,
                          ),
                        ),
                        child: _acceptTerms
                            ? const Icon(Icons.check, color: Colors.white, size: 13)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall,
                            children: const [
                              TextSpan(text: "J'accepte les "),
                              TextSpan(
                                text: "Conditions d'utilisation",
                                style: TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: " et la "),
                              TextSpan(
                                text: "Politique de confidentialité",
                                style: TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Consumer<AuthService>(
                  builder: (_, auth, _) => auth.error != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Center(
                            child: Text(auth.error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleRegister,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Créer mon compte'),
                  ),
                ),
                const SizedBox(height: 28),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Déjà un compte ? ', style: theme.textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text('Se connecter',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
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

  Widget _roleChip(String value, String label, IconData icon, bool isDark) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.cardDark : AppColors.inputFillLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
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
