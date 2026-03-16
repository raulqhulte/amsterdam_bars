import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bars.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bars (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE visits (
            id TEXT PRIMARY KEY,
            bar_id TEXT NOT NULL,
            visited_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reviews (
            bar_id TEXT PRIMARY KEY,
            rating INTEGER NOT NULL,
            notes TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS visits (
              id TEXT PRIMARY KEY,
              bar_id TEXT NOT NULL,
              visited_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reviews (
              bar_id TEXT PRIMARY KEY,
              rating INTEGER NOT NULL,
              notes TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }
}
