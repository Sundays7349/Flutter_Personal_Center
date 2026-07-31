import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class TodosRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  TodosRepository(this._db, this._getDeviceId);

  Future<List<Todo>> getByDate(String date) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_todos',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  Future<List<Todo>> getWeekRange(String startDate, String endDate) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_todos',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  Future<void> insert(Todo todo) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = todo.id.isEmpty ? const Uuid().v4() : todo.id;
    final map = todo.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'daily_todos',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> update(Todo todo) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'daily_todos',
      where: 'id = ?',
      whereArgs: [todo.id],
      limit: 1,
    );
    final map = todo.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'daily_todos',
      map,
      where: 'id = ?',
      whereArgs: [todo.id],
    );
    await _db.touchModified();
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(
      'daily_todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }
}
