import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/theme_provider.dart';

class _Doctor {
  final String name, specialty, price;
  final double rating;
  final int reviews;
  const _Doctor(
    this.name,
    this.specialty,
    this.rating,
    this.reviews,
    this.price,
  );
}

const _doctors = [
  _Doctor('Dr. Martin Leblanc', 'Cardiologue', 4.9, 142, '35€'),
  _Doctor('Dr. Sophie Roux', 'Pédiatre', 4.8, 98, '28€'),
  _Doctor('Dr. Karim Benali', 'Dentiste', 4.7, 203, '45€'),
  _Doctor('Dr. Claire Morel', 'Dermatologue', 4.6, 77, '40€'),
];

const _specialties = [
  'Tous',
  'Généraliste',
  'Dentiste',
  'Cardiologue',
  'Pédiatre',
  'Dermatologue',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selected = 'Tous';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context, isDark)),
            SliverToBoxAdapter(child: _searchBar(theme, isDark)),
            SliverToBoxAdapter(child: _chips(theme, isDark)),
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
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _doctorCard(_doctors[i], theme, isDark),
                ),
                childCount: _doctors.length,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool isDark) {
    return Container(
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
                  color: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.8),
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
              Consumer<ThemeProvider>(
                builder: (_, tp, __) => _iconBtn(
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
            'Plus de 200 spécialistes disponibles',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  Widget _searchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un médecin...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey),
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
  }

  Widget _chips(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _specialties[i];
          final sel = _selected == s;
          return GestureDetector(
            onTap: () => setState(() => _selected = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: sel
                      ? AppColors.primary
                      : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel
                      ? Colors.white
                      : isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _upcomingCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.85),
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
                color: Colors.white.withOpacity(0.2),
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
                    'Dr. Martin Leblanc',
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

  Widget _doctorCard(_Doctor doc, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        /* TODO: DoctorDetailScreen — Dev B */
      },
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(doc.specialty, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.star,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        doc.rating.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${doc.reviews} avis)',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  doc.price,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '/ consultation',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
  }
}
