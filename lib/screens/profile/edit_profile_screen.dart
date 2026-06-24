import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;

  String? _avatarBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _firstNameCtrl = TextEditingController(text: user?['firstName'] ?? '');
    _lastNameCtrl = TextEditingController(text: user?['lastName'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    final existing = user?['avatarUrl'];
    if (existing != null && existing.startsWith('data:')) {
      _avatarBase64 = existing;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 60, maxWidth: 400);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() => _avatarBase64 = 'data:image/jpeg;base64,$b64');
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Prendre une photo'),
                onTap: () => _pickPhoto(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => _pickPhoto(ImageSource.gallery),
              ),
              if (_avatarBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppColors.error),
                  title: const Text('Supprimer la photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _avatarBase64 = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthService>();
    final ok = await auth.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      avatarUrl: _avatarBase64,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthService>().currentUser;
    final initials = _initials(
      _firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text : (user?['firstName'] ?? ''),
      _lastNameCtrl.text.isNotEmpty ? _lastNameCtrl.text : (user?['lastName'] ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('Enregistrer',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _avatarBase64 != null
                          ? MemoryImage(base64Decode(_avatarBase64!.split(',').last))
                          : null,
                      child: _avatarBase64 == null
                          ? Text(initials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700))
                          : null,
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Changer la photo',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),

              _field(
                label: 'Prénom',
                controller: _firstNameCtrl,
                isDark: isDark,
                validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Nom',
                controller: _lastNameCtrl,
                isDark: isDark,
                validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Téléphone',
                controller: _phoneCtrl,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                hintText: '06 00 00 00 00',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(hintText: hintText ?? label),
        ),
      ],
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }
}
