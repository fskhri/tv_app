import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mosque_model.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'adzan_tv.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE mosque_settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mosque_name TEXT,
            latitude REAL,
            longitude REAL,
            running_text TEXT,
            enable_adzan_sound INTEGER,
            enable_iqamah_sound INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE contents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            path TEXT,
            display_order INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_status(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            last_sync TIMESTAMP,
            needs_sync INTEGER DEFAULT 0
          )
        ''');

        await db.insert('sync_status', {
          'id': 1,
          'last_sync': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        });

        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT,
            mosque_id TEXT,
            created_at TIMESTAMP,
            updated_at TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE prayer_schedules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
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
      },
    );
  }

  // CRUD Operations untuk Mosque Settings
  Future<int> saveMosqueSettings(MosqueModel mosque) async {
    final db = await database;
    // Cek apakah sudah ada data
    final List<Map<String, dynamic>> settings = await db.query('mosque_settings');
    
    final Map<String, dynamic> values = {
      'mosque_name': mosque.mosqueName,
      'latitude': mosque.latitude,
      'longitude': mosque.longitude,
      'running_text': mosque.runningText,
      'enable_adzan_sound': mosque.enableAdzanSound ? 1 : 0,
      'enable_iqamah_sound': mosque.enableIqamahSound ? 1 : 0,
    };
    
    if (settings.isEmpty) {
      return await db.insert('mosque_settings', values);
    } else {
      return await db.update(
        'mosque_settings',
        values,
        where: 'id = ?',
        whereArgs: [settings.first['id']],
      );
    }
  }

  Future<MosqueModel?> getMosqueSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> settings = await db.query('mosque_settings');
    
    if (settings.isEmpty) {
      return null;
    }
    
    return MosqueModel.fromMap(settings.first);
  }

  // CRUD Operations untuk Content
  Future<int> saveContent(ContentModel content) async {
    final db = await database;
    return await db.insert('contents', content.toMap());
  }

  Future<int> updateContent(ContentModel content) async {
    final db = await database;
    return await db.update(
      'contents',
      content.toMap(),
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  Future<int> deleteContent(int id) async {
    final db = await database;
    return await db.delete(
      'contents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ContentModel>> getAllContents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contents',
      orderBy: 'display_order ASC',
    );
    
    return List.generate(maps.length, (i) {
      return ContentModel.fromMap(maps[i]);
    });
  }

  Future<void> reorderContents(List<ContentModel> contents) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < contents.length; i++) {
        await txn.update(
          'contents',
          {'display_order': i},
          where: 'id = ?',
          whereArgs: [contents[i].id],
        );
      }
    });
  }

  // Method untuk backup database
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final List<Map<String, dynamic>> mosqueSettings = await db.query('mosque_settings');
    final List<Map<String, dynamic>> contents = await db.query('contents');

    return {
      'mosque_settings': mosqueSettings,
      'contents': contents,
    };
  }

  // Method untuk restore database
  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('mosque_settings');
      await txn.delete('contents');

      // Import mosque settings
      if (data['mosque_settings'] != null) {
        for (var settings in data['mosque_settings']) {
          await txn.insert('mosque_settings', settings);
        }
      }

      // Import contents
      if (data['contents'] != null) {
        for (var content in data['contents']) {
          await txn.insert('contents', content);
        }
      }
    });
  }

  // Method untuk membersihkan database
  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('mosque_settings');
      await txn.delete('contents');
    });
  }

  // CRUD Operations untuk User
  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> createUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations untuk Prayer Schedules
  Future<void> savePrayerSchedules(List<Map<String, dynamic>> schedules) async {
    final db = await database;
    await db.transaction((txn) async {
      // Hapus jadwal lama
      await txn.delete('prayer_schedules');
      // Simpan jadwal baru
      for (var schedule in schedules) {
        await txn.insert('prayer_schedules', {
          'date': schedule['key'],
          'imsak': schedule['imsak'],
          'subuh': schedule['subuh'],
          'terbit': schedule['terbit'],
          'dhuha': schedule['dhuha'],
          'dzuhur': schedule['dzuhur'],
          'ashar': schedule['ashar'],
          'maghrib': schedule['maghrib'],
          'isya': schedule['isya'],
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getPrayerSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> schedules = await db.query('prayer_schedules');
    return schedules.map((schedule) => {
      'key': schedule['date'],
      'imsak': schedule['imsak'],
      'subuh': schedule['subuh'],
      'terbit': schedule['terbit'],
      'dhuha': schedule['dhuha'],
      'dzuhur': schedule['dzuhur'],
      'ashar': schedule['ashar'],
      'maghrib': schedule['maghrib'],
      'isya': schedule['isya'],
    }).toList();
  }

  Future<void> markNeedsSync() async {
    final db = await database;
    try {
      await db.update(
        'sync_status',
        {'needs_sync': 1},
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      // Jika tabel belum ada, buat dan insert data awal
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_status(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          last_sync TIMESTAMP,
          needs_sync INTEGER DEFAULT 0
        )
      ''');
      
      await db.insert('sync_status', {
        'id': 1,
        'last_sync': DateTime.now().toIso8601String(),
        'needs_sync': 1,
      });
    }
  }
} 