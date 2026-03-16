import 'package:uuid/uuid.dart';

import 'database.dart';

class VisitsDao {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  Future<void> addVisit(String barId) async {
    final db = await _db.database;

    await db.insert('visits', {
      'id': _uuid.v4(),
      'bar_id': barId,
      'visited_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<DateTime>> getVisitsForBar(String barId) async {
    final db = await _db.database;

    final result = await db.query(
      'visits',
      where: 'bar_id = ?',
      whereArgs: [barId],
      orderBy: 'visited_at DESC',
    );

    return result
        .map((row) => DateTime.parse(row['visited_at'] as String))
        .toList();
  }

  /// Returns the most recent visit date for each bar_id (if any).
  Future<Map<String, DateTime>> getLastVisitsByBarId() async {
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT bar_id, MAX(visited_at) AS last_visit
      FROM visits
      GROUP BY bar_id
    ''');

    final map = <String, DateTime>{};
    for (final r in rows) {
      final barId = r['bar_id'] as String;
      final last = r['last_visit'] as String?;
      if (last != null) {
        map[barId] = DateTime.parse(last);
      }
    }
    return map;
  }
}
