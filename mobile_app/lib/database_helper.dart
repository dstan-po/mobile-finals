import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasePath = join(await getDatabasesPath(), 'theme.db');

    return openDatabase(databasePath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          theme_is_dark INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE user_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          encrypted_name TEXT
        )
      ''');
    });
  }

  Future<void> insertEncryptedName(String encryptedName) async {
    final db = await database;

    var result = await db.query(
      'user_data',
      where: 'id = ?',
      whereArgs: [0],
    );

    if (result.isEmpty) {
      await db.insert(
        'user_data',
        {'id': 0, 'encrypted_name': encryptedName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.update(
        'user_data',
        {'encrypted_name': encryptedName},
        where: 'id = ?',
        whereArgs: [0],
      );
    }
  }

  Future<String?> fetchEncryptedName(int id) async {
    final db = await database;

    List<Map<String, dynamic>> result = await db.query(
      'user_data',
      columns: ['encrypted_name'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first['encrypted_name'];
    } else {
      return null;
    }
  }

  Future<bool> getTheme() async {
    final db = await database;
    var result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isEmpty) {
      await _setTheme(false);
      return false;
    }
    return result.first['theme_is_dark'] == 1;
  }

  Future<void> _setTheme(bool isDark) async {
    final db = await database;
    await db.insert(
      'settings',
      {'theme_is_dark': isDark ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTheme(bool isDark) async {
    final db = await database;
    await db.update(
      'settings',
      {'theme_is_dark': isDark ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
