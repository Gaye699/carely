import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 🟢 Correction ici : Import absolu pour éviter le conflit de type de Dart
import 'package:carely/core/services/auth_service.dart';

import 'package:carely/screens/auth/login_screen.dart';
import 'package:carely/screens/auth/register_screen.dart';
import 'package:carely/screens/home/main_screen.dart';
import 'package:carely/screens/doctor/doctor_detail_screen.dart';
import 'package:carely/screens/appointment/book_appointment_screen.dart';
import 'package:carely/screens/appointment/my_appointments_screen.dart';
import 'package:carely/screens/profile/profile_screen.dart';
import 'package:carely/screens/admin/admin_screen.dart';

class AppRouter {
  static const _storage = FlutterSecureStorage();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: _redirect,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),

      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeTab()),
          GoRoute(
            path: '/appointments',
            builder: (_, __) => const MyAppointmentsScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
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
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn;
    final role = authService.currentUser?['role'];

    print(
      "🔑 [Router Debug] Route demandée : ${state.matchedLocation} | Connecté : $isLoggedIn | Rôle : $role",
    );

    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    if (state.matchedLocation == '/admin' && role != 'admin') return '/';

    return null;
  }
}
