import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/models/consultant.dart';
import '../../core/providers/consultant_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

const _dayNames = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

class DoctorDetailScreen extends StatelessWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final consultants = context.watch<ConsultantProvider>().allConsultants;
    final id = int.tryParse(doctorId);
    final Consultant? doctor =
        id != null ? consultants.where((c) => c.id == id).firstOrNull : null;

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('Médecin introuvable')),
      );
    }

    return _DoctorDetailView(doctor: doctor);
  }
}

class _DoctorDetailView extends StatefulWidget {
  final Consultant doctor;
  const _DoctorDetailView({required this.doctor});

  @override
  State<_DoctorDetailView> createState() => _DoctorDetailViewState();
}

class _DoctorDetailViewState extends State<_DoctorDetailView> {
  List<dynamic> _availability = [];
  bool _availLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final res = await http
          .get(
            Uri.parse('${AuthService.baseUrl}/doctors/${widget.doctor.id}/availability'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _availability = jsonDecode(res.body) as List;
          _availLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _availLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doctor = widget.doctor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppColors.headerGradient)),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _avatar(doctor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctor.fullName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(doctor.specialty,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 4),
                              if (doctor.city != null)
                                Text(doctor.city!,
                                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.star, size: 16),
                                  const SizedBox(width: 4),
                                  Text(doctor.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (doctor.available
                                              ? AppColors.success
                                              : AppColors.error)
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: doctor.available
                                              ? AppColors.success
                                              : AppColors.error),
                                    ),
                                    child: Text(
                                      doctor.available ? 'Disponible' : 'Indisponible',
                                      style: TextStyle(
                                          color: doctor.available
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Infos rapides
                  Row(
                    children: [
                      if (doctor.price != null && doctor.price! > 0)
                        _chip(Icons.euro_rounded, '${doctor.price!.toStringAsFixed(0)} €',
                            isDark),
                      if (doctor.price != null && doctor.price! > 0) const SizedBox(width: 8),
                      _chip(Icons.medical_services_outlined, doctor.specialty, isDark),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // À propos
                  _sectionTitle('À propos', theme, isDark),
                  const SizedBox(height: 10),
                  Text(
                    doctor.description != null && doctor.description!.isNotEmpty
                        ? doctor.description!
                        : 'Spécialiste en ${doctor.specialty.toLowerCase()}, '
                            '${doctor.fullName} accompagne ses patients avec une '
                            'approche personnalisée et bienveillante.',
                    style: TextStyle(
                      height: 1.6,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Horaires de consultation
                  _sectionTitle('Horaires de consultation', theme, isDark),
                  const SizedBox(height: 10),
                  if (_availLoading)
                    const Center(
                        child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_availability.isEmpty)
                    Text(
                      'Horaires non renseignés — contactez le cabinet.',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 13),
                    )
                  else
                    _availabilityWidget(isDark),

                  const SizedBox(height: 28),

                  // Infos contact
                  if (doctor.phone != null) ...[
                    _infoRow(Icons.phone_outlined, 'Téléphone', doctor.phone!, isDark),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: doctor.available
                          ? () => context.push('/book/${doctor.id}')
                          : null,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                          doctor.available ? 'Prendre rendez-vous' : 'Indisponible'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityWidget(bool isDark) {
    // Grouper par jour
    final Map<int, List<dynamic>> byDay = {};
    for (final slot in _availability) {
      final day = slot['dayOfWeek'] as int;
      byDay.putIfAbsent(day, () => []).add(slot);
    }

    return Column(
      children: byDay.entries.map((entry) {
        final day = entry.key;
        final slots = entry.value;
        final ranges = slots
            .map((s) => '${s['startHour']}h – ${s['endHour']}h')
            .join(', ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(_dayNames[day],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ranges,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _avatar(Consultant doctor) {
    final url = doctor.photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url != null && url.isNotEmpty && !url.startsWith('data:')
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 36));

  Widget _chip(IconData icon, String label, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ],
        ),
      );

  Widget _sectionTitle(String text, ThemeData theme, bool isDark) => Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      );

  Widget _infoRow(IconData icon, String label, String value, bool isDark) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
            ],
          ),
        ],
      );
}
