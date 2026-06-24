import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:carely/core/services/auth_service.dart';
import 'package:carely/screens/auth/login_screen.dart';
import 'package:carely/screens/auth/register_screen.dart';
import 'package:carely/screens/home/main_screen.dart';
import 'package:carely/screens/doctor/doctor_detail_screen.dart';
import 'package:carely/screens/appointment/book_appointment_screen.dart';
import 'package:carely/screens/appointment/my_appointments_screen.dart';
import 'package:carely/screens/profile/profile_screen.dart';
import 'package:carely/screens/admin/admin_screen.dart';
import 'package:carely/screens/search/search_screen.dart';
import 'package:carely/screens/doctor_portal/doctor_main_screen.dart';
import 'package:carely/screens/profile/edit_profile_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) => GoRouter(
    initialLocation: '/login',
    refreshListenable: authService,
    redirect: _redirect,
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),

      // Portail médecin
      ShellRoute(
        builder: (context, state, child) => DoctorMainScreen(child: child),
        routes: [
          GoRoute(path: '/doctor', builder: (_, _) => const DoctorHomeTab()),
          GoRoute(
            path: '/doctor/appointments',
            builder: (_, _) => const DoctorAppointmentsTab(),
          ),
          GoRoute(
            path: '/doctor/availability',
            builder: (_, _) => const DoctorAvailabilityTab(),
          ),
          GoRoute(
            path: '/doctor/profile',
            builder: (_, _) => const DoctorProfileTab(),
          ),
        ],
      ),

      // Portail patient
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeTab()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(
            path: '/appointments',
            builder: (_, _) => const MyAppointmentsScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),

      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/doctor/:id',
        builder: (_, state) =>
            DoctorDetailScreen(doctorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:doctorId',
        builder: (_, state) =>
            BookAppointmentScreen(doctorId: state.pathParameters['doctorId']!),
      ),
    ],
  );

  static Future<String?> _redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final auth = context.read<AuthService>();
    final isLoggedIn = auth.isLoggedIn;
    final role = auth.currentUser?['role'];
    final loc = state.matchedLocation;

    final isAuthRoute = loc == '/login' || loc == '/register';
    // Portail médecin uniquement
    const doctorPortalRoutes = {
      '/doctor',
      '/doctor/appointments',
      '/doctor/availability',
      '/doctor/profile',
    };
    final isDoctorPortalRoute = doctorPortalRoutes.contains(loc);

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) {
      if (role == 'doctor') return '/doctor';
      return '/';
    }
    if (isDoctorPortalRoute && role != 'doctor') return '/';
    if (isLoggedIn &&
        !isDoctorPortalRoute &&
        !isAuthRoute &&
        role == 'doctor') {
      const patientOnly = {
        '/',
        '/search',
        '/appointments',
        '/profile',
        '/profile/edit',
      };
      if (patientOnly.contains(loc)) return '/doctor';
    }

    return null;
  }
}
