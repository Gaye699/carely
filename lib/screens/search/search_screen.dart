import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/consultant.dart';
import '../../core/providers/consultant_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/consultant_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(isDark),
            _searchBar(theme, isDark),
            _domainChips(theme, isDark),
            const SizedBox(height: 8),
            Expanded(child: _body(theme, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
            const Text(
              'Trouver un médecin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Recherchez parmi nos spécialistes',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

  Widget _searchBar(ThemeData theme, bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: TextField(
          controller: _searchController,
          onChanged: (v) =>
              context.read<ConsultantProvider>().onSearchChanged(v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Nom, spécialité…',
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.grey),
            suffixIcon: ValueListenableBuilder(
              valueListenable: _searchController,
              builder: (_, value, _) => value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.grey, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ConsultantProvider>().clearSearch();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );

  Widget _domainChips(ThemeData theme, bool isDark) =>
      Consumer<ConsultantProvider>(
        builder: (_, provider, _) => SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            children: [
              _chip(
                label: 'Tous',
                selected: provider.selectedDomain == null,
                isDark: isDark,
                onTap: () => provider.selectDomain(null),
              ),
              ...ConsultantDomain.all.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _chip(
                    label: ConsultantDomain.label(d),
                    selected: provider.selectedDomain == d,
                    isDark: isDark,
                    onTap: () => provider.selectDomain(d),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _chip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
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

  Widget _body(ThemeData theme, bool isDark) =>
      Consumer<ConsultantProvider>(
        builder: (_, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.error != null) {
            return _emptyState(
              icon: Icons.error_outline_rounded,
              message: 'Une erreur est survenue',
              isDark: isDark,
            );
          }

          if (provider.consultants.isEmpty) {
            return _emptyState(
              icon: Icons.search_off_rounded,

              message: 'Aucun médecin trouvé',
              isDark: isDark,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: provider.consultants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => ConsultantCard(
              consultant: provider.consultants[i],
            ),
          );
        },
      );

  Widget _emptyState({
    required IconData icon,
    required String message,
    required bool isDark,
  }) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
}
