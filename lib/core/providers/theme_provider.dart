import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'isDarkMode';
  bool _isDark = false;
  bool _disposed = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _load();
  }

  // _load() is async so notifyListeners() fires only after the await,
  // i.e., outside any build() — no assertion risk here.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    if (!_disposed) notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    // Notify before the await so the UI updates immediately on the tap frame,
    // not after the SharedPreferences write completes.
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
