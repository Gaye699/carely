import 'package:flutter/material.dart';
import '../../../core/models/consultant.dart';
import '../../../core/theme/app_colors.dart';

class ConsultantCard extends StatelessWidget {
  const ConsultantCard({super.key, required this.consultant, this.onTap});

  final Consultant consultant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
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
            _photo(),
            const SizedBox(width: 14),
            Expanded(child: _info(theme, isDark)),
            const SizedBox(width: 8),
            _badge(theme),
          ],
        ),
      ),
    );
  }

  Widget _photo() {
    final url = consultant.photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 60,
        height: 60,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarPlaceholder(),
              )
            : _avatarPlaceholder(),
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
        ),
      );

  Widget _info(ThemeData theme, bool isDark) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consultant.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            consultant.specialty,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.star, size: 15),
              const SizedBox(width: 3),
              Text(
                consultant.rating.toStringAsFixed(1),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _badge(ThemeData theme) {
    final available = consultant.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        available ? 'Disponible' : 'Indisponible',
        style: TextStyle(
          color: available ? AppColors.success : AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
