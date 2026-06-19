import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wifi_logger.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE speed_tests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            network_name TEXT,
            download_speed REAL,
            upload_speed REAL,
            ping INTEGER,
            tested_at TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertResult({
    required String networkName,
    required double downloadSpeed,
    required double uploadSpeed,
    required int ping,
    required String testedAt,
  }) async {
    final db = await database;
    await db.insert('speed_tests', {
      'network_name': networkName,
      'download_speed': downloadSpeed,
      'upload_speed': uploadSpeed,
      'ping': ping,
      'tested_at': testedAt,
    });
  }

  static Future<List<Map<String, dynamic>>> getResults() async {
    final db = await database;
    return await db.query('speed_tests', orderBy: 'id DESC');
  }

  static Future<void> deleteAll() async {
    final db = await database;
    await db.delete('speed_tests');
  }
}
