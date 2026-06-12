import '../database/database_helper.dart';
import '../models/consultant.dart';

class ConsultantRepository {
  Future<List<Consultant>> search({
    String? query,
    String? domain,
  }) async {
    final db = await DatabaseHelper.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      conditions.add('(LOWER(full_name) LIKE ? OR LOWER(specialty) LIKE ?)');
      final q = '%${query.trim().toLowerCase()}%';
      args..add(q)..add(q);
    }

    if (domain != null && domain.isNotEmpty) {
      conditions.add('domain = ?');
      args.add(domain);
    }

    final maps = await db.query(
      'consultants',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'rating DESC',
    );

    return maps.map(Consultant.fromMap).toList();
  }
}
