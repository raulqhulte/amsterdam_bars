import 'package:uuid/uuid.dart';
import 'database.dart';
import '../models/bar.dart';

class BarsDao {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  Future<void> insertBar(String name, double lat, double lng) async {
    final db = await _db.database;

    final bar = Bar(
      id: _uuid.v4(),
      name: name,
      latitude: lat,
      longitude: lng,
    );

    await db.insert('bars', bar.toMap());
  }

  Future<List<Bar>> getAllBars() async {
    final db = await _db.database;
    final result = await db.query('bars');

    return result.map((e) => Bar.fromMap(e)).toList();
  }
  Future<Map<String, int>> getVisitCountsByBarId() async {
  final db = await _db.database;

  final rows = await db.rawQuery('''
    SELECT bar_id, COUNT(*) AS c
    FROM visits
    GROUP BY bar_id
  ''');

  final map = <String, int>{};
  for (final r in rows) {
    map[r['bar_id'] as String] = (r['c'] as int?) ?? 0;
  }
  return map;
}

}
