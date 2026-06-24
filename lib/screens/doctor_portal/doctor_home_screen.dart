import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _todayAppointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${AuthService.baseUrl}/doctor/me'), headers: headers),
        http.get(
          Uri.parse('${AuthService.baseUrl}/doctor/appointments?filter=today'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        if (results[0].statusCode == 200) {
          _profile = jsonDecode(results[0].body) as Map<String, dynamic>;
        }
        if (results[1].statusCode == 200) {
          _todayAppointments = jsonDecode(results[1].body) as List;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final firstName = auth.currentUser?['firstName'] ?? 'Docteur';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _doctorAvatar(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Bonjour, Dr. $firstName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile != null
                                  ? _profile!['specialty'] as String? ?? ''
                                  : '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (_profile != null && (_profile!['isVerified'] as int? ?? 0) == 0)
                  Container(
                    margin: const EdgeInsets.only(right: 16, top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'En attente de vérification',
                      style: TextStyle(color: Colors.orange, fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Carte stats
                    Row(
                      children: [
                        _statCard(
                          Icons.today_rounded,
                          '${_todayAppointments.length}',
                          "Aujourd'hui",
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          Icons.schedule_rounded,
                          _profile != null ? _profile!['price']?.toString() ?? '0' : '0',
                          'Tarif (€)',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Actions rapides
                    Text(
                      'Actions rapides',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _quickAction(
                          Icons.schedule_rounded,
                          'Mes horaires',
                          () => context.go('/doctor/availability'),
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _quickAction(
                          Icons.calendar_month_rounded,
                          'Tous mes RDV',
                          () => context.go('/doctor/appointments'),
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _quickAction(
                          Icons.person_rounded,
                          'Mon profil',
                          () => context.go('/doctor/profile'),
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Rendez-vous du jour
                    Text(
                      "Rendez-vous d'aujourd'hui",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_todayAppointments.isEmpty)
                      _emptyState(isDark)
                    else
                      ..._todayAppointments.map((a) => _appointmentCard(a, isDark)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    )),
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appt, bool isDark) {
    final time = appt['dateTime'] as String? ?? '';
    final hour = time.length >= 16 ? time.substring(11, 16) : time;
    final patientName =
        '${appt['patientFirstName'] ?? ''} ${appt['patientLastName'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(hour,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    )),
                if (appt['reason'] != null && appt['reason'].toString().isNotEmpty)
                  Text(appt['reason'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Confirmé',
                style: TextStyle(
                    color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _doctorAvatar() {
    final url = _profile?['avatarUrl'] as String?;
    ImageProvider? img;
    if (url != null && url.startsWith('data:')) {
      final b64 = url.split(',').last;
      img = MemoryImage(base64Decode(b64));
    } else if (url != null && url.isNotEmpty) {
      img = NetworkImage(url);
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      backgroundImage: img,
      child: img == null
          ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
          : null,
    );
  }

  Widget _emptyState(bool isDark) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.event_available_rounded,
                size: 48,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 12),
            Text("Aucun rendez-vous aujourd'hui",
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                )),
          ],
        ),
      );
}
