import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../models/consultant.dart';
import '../services/auth_service.dart';

class ConsultantRepository {
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

  // Forces a reload from the API on next search() call (call after admin changes).
  void invalidate() {
    _loaded = false;
    _cache = [];
  }

  Future<void> _loadData() async {
    // Try backend API first — this is the source of truth for admin-managed doctors.
    try {
      final res = await http
          .get(Uri.parse('${AuthService.baseUrl}/doctors'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _cache = list
            .map((m) => Consultant.fromApiMap(m as Map<String, dynamic>))
            .toList();
        _loaded = true;
        return;
      }
    } catch (_) {
      // Backend unreachable — fall through to local SQLite.
    }

    // Fallback: read from the local seed database.
    final db = await DatabaseHelper.database;
    final maps = await db.query('consultants', orderBy: 'rating DESC');
    _cache = maps.map(Consultant.fromMap).toList();
    _loaded = true;
  }
}
