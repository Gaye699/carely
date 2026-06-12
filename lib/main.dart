import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/providers/consultant_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/repositories/consultant_repository.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // lazy: false — create immediately during MultiProvider's own mount,
        // not on first access inside a build(). This prevents the provider
        // element from being created (and potentially notifying) while a
        // descendant widget is already mid-build.
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
    // context.watch is preferred over Consumer here: it avoids creating an
    // extra builder scope and makes the dependency chain unambiguous.
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      title: 'Carely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const LoginScreen(),
    );
  }
}
