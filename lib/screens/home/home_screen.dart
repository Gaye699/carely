import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/models/consultant.dart';
import '../../core/providers/consultant_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedDomain;
  Map<String, dynamic>? _nextAppointment;
  bool _loadingAppt = true;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
  }

  Future<void> _loadNextAppointment() async {
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final res = await http
          .get(Uri.parse('${AuthService.baseUrl}/appointments/mine'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        final now = DateTime.now();
        final upcoming = list.where((a) {
          final dt = (a as Map<String, dynamic>)['dateTime'] as String? ?? '';
          final parsed = DateTime.tryParse(dt);
          return parsed != null && parsed.isAfter(now) && a['status'] == 'confirmed';
        }).toList();
        setState(() {
          _nextAppointment = upcoming.isNotEmpty ? upcoming.first as Map<String, dynamic> : null;
          _loadingAppt = false;
        });
      } else {
        if (mounted) setState(() => _loadingAppt = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAppt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final consultantProvider = context.watch<ConsultantProvider>();

    final filtered = _selectedDomain == null
        ? consultantProvider.allConsultants
        : consultantProvider.allConsultants
            .where((c) => c.domain == _selectedDomain)
            .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _header(context, isDark, consultantProvider.allConsultants.length),
            ),
            SliverToBoxAdapter(child: _searchBar(context)),
            SliverToBoxAdapter(child: _chips(isDark)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _upcomingCard(isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Médecins populaires',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/search'),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
            ),
            if (consultantProvider.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Aucun médecin dans cette spécialité',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _doctorCard(filtered[i], theme, isDark),
                    childCount: filtered.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  // ── Header avec avatar ────────────────────────────────────────────────

  Widget _header(BuildContext context, bool isDark, int count) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Consumer<AuthService>(
                  builder: (_, auth, _) => _userAvatar(auth),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour,',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                      Consumer<AuthService>(
                        builder: (_, auth, _) {
                          final user = auth.currentUser;
                          final name = user != null
                              ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
                              : '';
                          return Text(
                            name.isNotEmpty ? name : 'Utilisateur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _iconBtn(Icons.notifications_outlined),
                const SizedBox(width: 8),
                Consumer<ThemeProvider>(
                  builder: (_, tp, _) => _iconBtn(
                    tp.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    onTap: tp.toggle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Trouvez votre\nmédecin idéal',
              style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count spécialiste${count == 1 ? '' : 's'} disponibles',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
      );

  Widget _userAvatar(AuthService auth) {
    final url = auth.currentUser?['avatarUrl'];
    if (url != null && url.startsWith('data:')) {
      final b64 = url.split(',').last;
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        backgroundImage: MemoryImage(base64Decode(b64)),
      );
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _searchBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: GestureDetector(
          onTap: () => context.go('/search'),
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un médecin…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
      );

  // ── Domain chips ──────────────────────────────────────────────────────

  Widget _chips(bool isDark) => SizedBox(
        height: 92,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          children: [
            _iconChip(label: 'Tous', icon: Icons.apps_rounded, domain: null, isDark: isDark),
            ...ConsultantDomain.all.map(
              (d) => Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _iconChip(
                  label: ConsultantDomain.shortLabel(d),
                  icon: ConsultantDomain.icon(d),
                  domain: d,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _iconChip({
    required String label,
    required IconData icon,
    required String? domain,
    required bool isDark,
  }) {
    final selected = _selectedDomain == domain;
    return GestureDetector(
      onTap: () => setState(() => _selectedDomain = domain),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : (isDark ? AppColors.cardDark : AppColors.grey50),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Icon(icon,
                color: selected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.primary),
                size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              )),
        ],
      ),
    );
  }

  // ── Prochain RDV (dynamique) ──────────────────────────────────────────

  Widget _upcomingCard(bool isDark) {
    if (_loadingAppt) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_nextAppointment == null) {
      return GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aucun rendez-vous à venir',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Touchez pour trouver un médecin',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ],
          ),
        ),
      );
    }

    final appt = _nextAppointment!;
    final dt = appt['dateTime'] as String? ?? '';
    final date = dt.length >= 10 ? dt.substring(0, 10) : '';
    final time = dt.length >= 16 ? dt.substring(11, 16) : '';
    final doctorName = appt['doctorName'] as String? ?? '';
    final specialty = appt['doctorSpecialty'] as String? ?? '';

    final parts = date.split('-');
    const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final m = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final day = parts.length >= 3 ? parts[2] : '';
    final year = parts.isNotEmpty ? parts[0] : '';
    final monthStr = m > 0 && m < months.length ? months[m] : '';
    final formattedDate = '$day $monthStr $year'.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('Prochain rendez-vous',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _info(Icons.calendar_today_outlined, formattedDate),
              const SizedBox(width: 20),
              _info(Icons.access_time_rounded, time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      );

  // ── Doctor card (grid) ────────────────────────────────────────────────

  Widget _doctorCard(Consultant c, ThemeData theme, bool isDark) => GestureDetector(
        onTap: () => context.push('/doctor/${c.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _photo(c.photoUrl),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.available
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.available ? 'Dispo' : 'Indispo',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: c.available ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                c.specialty,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.star, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    c.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _photo(String? url) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 52, height: 52,
          child: url != null
              ? Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarFallback())
              : _avatarFallback(),
        ),
      );

  Widget _avatarFallback() => Container(
        color: AppColors.primaryLight,
        child: const Center(
            child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28)));
}
