import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  Map<String, dynamic>? _profile;
  XFile? _pickedImage;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final res = await http
          .get(Uri.parse('${AuthService.baseUrl}/doctor/me'), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final profile = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _profile = profile;
          _descCtrl.text = profile['description'] as String? ?? '';
          _addressCtrl.text = profile['address'] as String? ?? '';
          _cityCtrl.text = profile['city'] as String? ?? '';
          _phoneCtrl.text = profile['phone'] as String? ?? '';
          _priceCtrl.text = profile['price']?.toString() ?? '0';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
        source: source, imageQuality: 70, maxWidth: 512);
    if (file != null) setState(() => _pickedImage = file);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();

    String? avatarUrl;
    if (_pickedImage != null) {
      final bytes = await File(_pickedImage!.path).readAsBytes();
      avatarUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    try {
      final body = <String, dynamic>{
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
      };
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

      final res = await http
          .put(
            Uri.parse('${AuthService.baseUrl}/doctor/me'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _saving = false);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.success),
        );
        setState(() {
          _profile = jsonDecode(res.body) as Map<String, dynamic>;
          _pickedImage = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sauvegarder',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _showImagePicker,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(File(_pickedImage!.path))
                                  : null,
                              child: _pickedImage == null
                                  ? (_profile?['avatarUrl'] != null &&
                                          !(_profile!['avatarUrl'] as String)
                                              .startsWith('data:'))
                                      ? null
                                      : const Icon(Icons.person_rounded,
                                          size: 52, color: AppColors.primary)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isDark ? AppColors.cardDark : Colors.white,
                                      width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_profile != null) ...[
                      Center(
                        child: Text(
                          'Dr. ${_profile!['firstName']} ${_profile!['lastName']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          _profile!['specialty'] as String? ?? '',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      if ((_profile!['isVerified'] as int? ?? 0) == 0)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text('En attente de vérification RPPS',
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                    const SizedBox(height: 28),

                    _label('Description / À propos', theme, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Décrivez votre parcours, votre approche...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Téléphone cabinet', theme, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+33 6 00 00 00 00',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Adresse', theme, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        hintText: '12 rue de la Paix',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Ville', theme, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Paris',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Tarif de consultation (€)', theme, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '25',
                        prefixIcon: Icon(Icons.euro_outlined),
                      ),
                    ),
                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        label: const Text('Se déconnecter',
                            style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
