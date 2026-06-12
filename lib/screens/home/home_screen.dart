import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/consultant.dart';
import '../../core/providers/consultant_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // null = "Tous"
  String? _selectedDomain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch at the top of build so no Consumer ends up inside slivers.
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
            SliverToBoxAdapter(child: _searchBar()),
            SliverToBoxAdapter(child: _chips(isDark)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _upcomingCard(),
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
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
            ),
            // Sliver list — built from plain data, no Consumer wrapper.
            if (consultantProvider.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Aucun médecin dans cette spécialité',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.grey),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _doctorCard(filtered[i], theme, isDark),
                  ),
                  childCount: filtered.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour 👋',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        'Jean Dupont',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _iconBtn(Icons.notifications_outlined),
                const SizedBox(width: 8),
                // Consumer<ThemeProvider> is fine here — it's inside
                // SliverToBoxAdapter's child, not directly in slivers.
                Consumer<ThemeProvider>(
                  builder: (_, tp, _) => _iconBtn(
                    tp.isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: tp.toggle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Trouvez votre\nmédecin idéal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count spécialiste${count == 1 ? '' : 's'} disponibles',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un médecin…',
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.grey),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      );

  // ── Domain chips ──────────────────────────────────────────────────────

  Widget _chips(bool isDark) => SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          children: [
            _chip(label: 'Tous', domain: null, isDark: isDark),
            ...ConsultantDomain.all.map(
              (d) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _chip(
                  label: ConsultantDomain.label(d),
                  domain: d,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _chip({
    required String label,
    required String? domain,
    required bool isDark,
  }) {
    final selected = _selectedDomain == domain;
    return GestureDetector(
      onTap: () => setState(() => _selectedDomain = domain),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? Colors.white
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  // ── Upcoming appointment card ──────────────────────────────────────────

  Widget _upcomingCard() => Container(
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
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Prochain rendez-vous',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Thomas Dupont',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cardiologue',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
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
                _info(Icons.calendar_today_outlined, 'Mer. 22 mai 2024'),
                const SizedBox(width: 20),
                _info(Icons.access_time_rounded, '14h30'),
              ],
            ),
          ],
        ),
      );

  Widget _info(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  // ── Doctor card ────────────────────────────────────────────────────────

  Widget _doctorCard(Consultant c, ThemeData theme, bool isDark) =>
      GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              _photo(c.photoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(c.specialty, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.star, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          c.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.available
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.available ? 'Disponible' : 'Indisponible',
                      style: TextStyle(
                        color: c.available
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Réserver',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _photo(String? url) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 60,
          height: 60,
          child: url != null
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarFallback(),
                )
              : _avatarFallback(),
        ),
      );

  Widget _avatarFallback() => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child:
              Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
        ),
      );
}
