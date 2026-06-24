import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/consultant.dart';
import '../services/auth_service.dart';

class ConsultantRepository {
  static const _storage = FlutterSecureStorage();
  List<Consultant> _cache = [];
  bool _loaded = false;

  Future<List<Consultant>> search({String? query, String? domain}) async {
    if (!_loaded) await _loadData();

    var results = _cache;

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results
          .where((c) =>
              c.fullName.toLowerCase().contains(q) ||
              c.specialty.toLowerCase().contains(q))
          .toList();
    }

    if (domain != null && domain.isNotEmpty) {
      results = results.where((c) => c.domain == domain).toList();
    }

    return List.from(results);
  }

  void invalidate() {
    _loaded = false;
    _cache = [];
  }

  Future<void> _loadData() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _cache = [];
        _loaded = true;
        return;
      }
      final res = await http
          .get(
            Uri.parse('${AuthService.baseUrl}/doctors'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _cache = list
            .map((m) => Consultant.fromApiMap(m as Map<String, dynamic>))
            .toList();
        _loaded = true;
        return;
      }
    } catch (_) {}
    _cache = [];
    _loaded = true;
  }
}
