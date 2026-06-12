import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/providers/consultant_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(
    MultiProvider(
      // ← MultiProvider au lieu de ChangeNotifierProvider
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()), // ← ajouter
      ],
      child: const CarelyApp(),
    ),
  );
}

class CarelyApp extends StatelessWidget {
  const CarelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp.router(
        title: 'Carely',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
