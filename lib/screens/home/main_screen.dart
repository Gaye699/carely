import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../home/home_screen.dart';
import '../../core/theme/app_colors.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc == '/') return 0;
    if (loc == '/search') return 1;
    if (loc == '/appointments') return 2;
    if (loc == '/profile') return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/search');
            case 2:
              context.go('/appointments');
            case 3:
              context.go('/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/ic_home.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/ic_home.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            ),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/ic_search.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/ic_search.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            ),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/ic_calendar.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/ic_calendar.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            ),
            label: 'Mes RDV',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/ic_profile.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/ic_profile.svg',
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
