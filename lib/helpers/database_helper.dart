import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer_schedule.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('prayer_schedules.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_schedules(
        key TEXT PRIMARY KEY,
        tanggal TEXT,
        imsak TEXT,
        subuh TEXT,
        terbit TEXT,
        dhuha TEXT,
        dzuhur TEXT,
        ashar TEXT,
        maghrib TEXT,
        isya TEXT
      )
    ''');
  }

  Future<void> savePrayerSchedules(List<Map<String, dynamic>> schedules) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('prayer_schedules');
      for (var schedule in schedules) {
        await txn.insert('prayer_schedules', schedule);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getPrayerSchedules() async {
    final db = await database;
    return await db.query('prayer_schedules');
  }
} 