import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer_schedule.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('prayer_times.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prayer_name TEXT NOT NULL,
        time TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertPrayerSchedule(PrayerSchedule schedule) async {
    final db = await instance.database;
    return await db.insert('prayer_schedules', schedule.toMap());
  }

  Future<List<PrayerSchedule>> getAllPrayerSchedules() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('prayer_schedules');
    
    return List.generate(maps.length, (i) {
      return PrayerSchedule.fromMap(maps[i]);
    });
  }

  Future<void> deleteAllPrayerSchedules() async {
    final db = await instance.database;
    await db.delete('prayer_schedules');
  }
} 