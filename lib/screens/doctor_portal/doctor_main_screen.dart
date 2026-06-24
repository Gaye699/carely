import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'doctor_home_screen.dart';
import 'doctor_availability_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorMainScreen extends StatelessWidget {
  final Widget child;
  const DoctorMainScreen({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc == '/doctor') return 0;
    if (loc == '/doctor/appointments') return 1;
    if (loc == '/doctor/availability') return 2;
    if (loc == '/doctor/profile') return 3;
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
            case 0: context.go('/doctor');
            case 1: context.go('/doctor/appointments');
            case 2: context.go('/doctor/availability');
            case 3: context.go('/doctor/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Rendez-vous',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule_rounded),
            label: 'Horaires',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class DoctorHomeTab extends StatelessWidget {
  const DoctorHomeTab({super.key});
  @override
  Widget build(BuildContext context) => const DoctorHomeScreen();
}

class DoctorAppointmentsTab extends StatelessWidget {
  const DoctorAppointmentsTab({super.key});
  @override
  Widget build(BuildContext context) => const DoctorAppointmentsScreen();
}

class DoctorAvailabilityTab extends StatelessWidget {
  const DoctorAvailabilityTab({super.key});
  @override
  Widget build(BuildContext context) => const DoctorAvailabilityScreen();
}

class DoctorProfileTab extends StatelessWidget {
  const DoctorProfileTab({super.key});
  @override
  Widget build(BuildContext context) => const DoctorProfileScreen();
}
