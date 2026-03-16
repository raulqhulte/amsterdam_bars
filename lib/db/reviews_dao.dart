import 'package:sqflite/sqflite.dart';

import 'database.dart';

class ReviewData {
  final int rating; // 0..5
  final String notes;

  ReviewData({
    required this.rating,
    required this.notes,
  });
}

class ReviewsDao {
  final _db = AppDatabase.instance;

  /// Get review for a single bar
  Future<ReviewData?> getReview(String barId) async {
    final db = await _db.database;

    final rows = await db.query(
      'reviews',
      where: 'bar_id = ?',
      whereArgs: [barId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final r = rows.first;
    return ReviewData(
      rating: (r['rating'] as int?) ?? 0,
      notes: (r['notes'] as String?) ?? '',
    );
  }

  /// Insert or update review for a bar
  Future<void> upsertReview(
    String barId,
    int rating,
    String notes,
  ) async {
    final db = await _db.database;

    await db.insert(
      'reviews',
      {
        'bar_id': barId,
        'rating': rating,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// NEW: get all reviews indexed by barId
  Future<Map<String, ReviewData>> getAllReviewsByBarId() async {
    final db = await _db.database;

    final rows = await db.query('reviews');
    final map = <String, ReviewData>{};

    for (final r in rows) {
      final barId = r['bar_id'] as String;
      map[barId] = ReviewData(
        rating: (r['rating'] as int?) ?? 0,
        notes: (r['notes'] as String?) ?? '',
      );
    }

    return map;
  }
}
