import 'package:flutter/material.dart';
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
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => ConsultantProvider(ConsultantRepository()),
        ),
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
