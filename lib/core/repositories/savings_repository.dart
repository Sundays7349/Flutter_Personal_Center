import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class SavingsRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  SavingsRepository(this._db, this._getDeviceId);

  Future<SavingsGoal?> getGoal() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SavingsGoal.fromMap(maps.first);
  }

  Future<void> saveGoal(SavingsGoal goal) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    final map = goal.toMap();
    map['id'] = 1;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    if (existing.isNotEmpty) {
      await db.update(
        'savings_goals',
        map,
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      await db.insert(
        'savings_goals',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await _db.touchModified();
  }

  Future<List<SavingsRecord>> getAllRecords() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_records',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SavingsRecord.fromMap(maps[i]));
  }

  Future<List<SavingsRecord>> getRecordsByMonth(String yyyyMm) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_records',
      where: 'date LIKE ?',
      whereArgs: ['$yyyyMm%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SavingsRecord.fromMap(maps[i]));
  }

  Future<void> insertRecord(SavingsRecord record) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = record.id.isEmpty ? const Uuid().v4() : record.id;
    final map = record.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'savings_records',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> deleteRecord(String id) async {
    final db = await _db.database;
    await db.delete(
      'savings_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<SavingsSubgoal>> getAllSubgoals() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_subgoals',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SavingsSubgoal.fromMap(maps[i]));
  }

  Future<void> insertSubgoal(SavingsSubgoal subgoal) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = subgoal.id.isEmpty ? const Uuid().v4() : subgoal.id;
    final map = subgoal.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'savings_subgoals',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateSubgoal(SavingsSubgoal subgoal) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'savings_subgoals',
      where: 'id = ?',
      whereArgs: [subgoal.id],
      limit: 1,
    );
    final map = subgoal.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'savings_subgoals',
      map,
      where: 'id = ?',
      whereArgs: [subgoal.id],
    );
    await _db.touchModified();
  }

  Future<void> deleteSubgoal(String id) async {
    final db = await _db.database;
    // 删除小目标时，将关联的存款记录标记回“计入总体”
    await db.update(
      'savings_records',
      {'subgoal_id': null},
      where: 'subgoal_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'savings_subgoals',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }
}
