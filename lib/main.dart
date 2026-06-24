import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/providers/consultant_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/repositories/consultant_repository.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();

  final authService = AuthService();
  final router = AppRouter.createRouter(authService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => ConsultantProvider(ConsultantRepository()),
        ),
      ],
      child: CarelyApp(router: router),
    ),
  );
}

class CarelyApp extends StatelessWidget {
  final GoRouter router;
  const CarelyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp.router(
        title: 'Carely',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        routerConfig: router,
      ),
    );
  }
}
