import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  // En dev local : changer selon l'appareil utilisé
  // Emulateur Android  → http://10.0.2.2:3000/api
  // Simulateur iOS     → http://localhost:3000/api
  // Téléphone physique → http://TON_IP_LOCAL:3000/api  (ex: 192.168.1.42)
  // Production Railway → https://carely-backend.up.railway.app/api
  static String get baseUrl {
    if (kDebugMode) return 'http://10.0.2.2:3000/api';
    return 'https://carely-backend.up.railway.app/api';
  }

  bool _isLoading = false;
  String? _error;
  Map<String, String>? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String>? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isLoggedIn => _currentUser != null;

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> checkAuth() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false;
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentUser = _toStringMap(data);

        if (data['role'] != null) {
          await _storage.write(
            key: 'user_role',
            value: data['role'].toString(),
          );
        }

        notifyListeners();
        return true;
      }
      await logout();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        await _saveSession(data);
        _setLoading(false);
        return true;
      }
      _error = data['error'] ?? 'Email ou mot de passe incorrect';
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Connexion impossible. Vérifiez votre réseau.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firstName': firstName.trim(),
              'lastName': lastName.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        await _saveSession(data);
        _setLoading(false);
        return true;
      }
      _error = data['error'] ?? 'Erreur lors de l\'inscription';
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Connexion impossible. Réessayez.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;

    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(
      key: 'user_role',
      value: user['role']?.toString() ?? '',
    );

    _currentUser = _toStringMap(user);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Map<String, String> _toStringMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, value.toString()));
  }
}
