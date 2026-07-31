import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../utils/sync_trigger.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  factory AppDatabase() => instance;

  AppDatabase._internal();

  /// 全部业务表名（用于云同步导出/导入）
  static const List<String> tableNames = [
    'daily_todos',
    'shooting_projects',
    'shooting_ideas',
    'memo_notes',
    'memo_contacts',
    'memo_shoppings',
    'study_papers',
    'study_experiments',
    'study_english',
    'fitness_workouts',
    'fitness_bodies',
    'fitness_diets',
    'savings_goals',
    'savings_records',
    'savings_subgoals',
    'accounting_records',
    'accounting_budgets',
  ];

  static const String _metaTable = 'sync_meta';
  static const String _keyLastModified = 'last_modified';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init();
    return _database!;
  }

  Future<Database> _init() async {
    late String fullPath;
    if (kIsWeb) {
      // Web: use a simple name (stored in IndexedDB via sqflite_common_ffi_web)
      fullPath = 'shining_personal_web.db';
    } else {
      // Desktop: use the standard databases path
      final dbPath = await getDatabasesPath();
      fullPath = path.join(dbPath, 'shining_personal.db');
    }

    return await openDatabase(
      fullPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS fitness_diets');
      await db.execute('''
        CREATE TABLE fitness_diets (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          meal_type TEXT NOT NULL,
          food TEXT NOT NULL,
          calories INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          device_id TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 1
        );
      ''');
    }
    if (oldVersion < 3) {
      await _createSyncMeta(db);
      // 用已有数据的最大 updated_at 初始化“数据库最后修改时间”，
      // 避免升级后首次同步因时间戳为 0 而误用云端数据覆盖本地
      final maxUpdatedAt = await _maxUpdatedAt(db);
      await db.insert(
        _metaTable,
        {'key': _keyLastModified, 'value': maxUpdatedAt},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (oldVersion < 4) {
      // 存款记录可关联小目标（计入小目标的款项不计入总体）
      await db.execute('ALTER TABLE savings_records ADD COLUMN subgoal_id TEXT');
      // 小目标支持“已完成”状态
      await db.execute('ALTER TABLE savings_subgoals ADD COLUMN completed INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _createSyncMeta(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      );
    ''');
  }

  /// 计算所有业务表中最大的 updated_at（用于升级迁移初始化）
  Future<int> _maxUpdatedAt(Database db) async {
    int max = 0;
    for (final table in tableNames) {
      try {
        final result = await db.rawQuery('SELECT MAX(updated_at) as m FROM $table');
        final value = result.first['m'] as int? ?? 0;
        if (value > max) max = value;
      } catch (e) {
        // 表可能不存在，跳过
      }
    }
    return max;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_todos (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE shooting_projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        shoot_date TEXT,
        price REAL NOT NULL DEFAULT 0,
        cost REAL NOT NULL DEFAULT 0,
        participants TEXT,
        done INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE shooting_ideas (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE memo_notes (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE memo_contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        account TEXT,
        password TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE memo_shoppings (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE study_papers (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE study_experiments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        date TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE study_english (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        words INTEGER NOT NULL DEFAULT 0,
        minutes INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE fitness_workouts (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        duration INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE fitness_bodies (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL,
        chest REAL,
        waist REAL,
        hip REAL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE fitness_diets (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food TEXT NOT NULL,
        calories INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_goal REAL NOT NULL DEFAULT 0,
        monthly_goal REAL NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE savings_records (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        note TEXT,
        subgoal_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE savings_subgoals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target REAL NOT NULL DEFAULT 0,
        current REAL NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE accounting_records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE accounting_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthly REAL NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await _createSyncMeta(db);
  }

  /// 记录一次数据修改：更新"数据库最后修改时间"为当前时间
  Future<void> touchModified() async {
    final db = await database;
    await db.insert(
      _metaTable,
      {'key': _keyLastModified, 'value': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // 通知应用层触发一次云端同步（增删改后自动同步）
    SyncTrigger.notifyDataChanged();
  }

  /// 获取“数据库最后修改时间”（毫秒时间戳），无记录时返回 0
  Future<int> getLastModified() async {
    final db = await database;
    final rows = await db.query(
      _metaTable,
      where: 'key = ?',
      whereArgs: [_keyLastModified],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return rows.first['value'] as int? ?? 0;
  }

  /// 设置“数据库最后修改时间”（用于云端覆盖本地后与云端保持一致）
  Future<void> setLastModified(int timestamp) async {
    final db = await database;
    await db.insert(
      _metaTable,
      {'key': _keyLastModified, 'value': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
