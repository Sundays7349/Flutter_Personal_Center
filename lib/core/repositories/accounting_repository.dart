import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class AccountingRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  AccountingRepository(this._db, this._getDeviceId);

  Future<AccountingBudget?> getBudget() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounting_budgets',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AccountingBudget.fromMap(maps.first);
  }

  Future<void> saveBudget(AccountingBudget budget) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'accounting_budgets',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    final map = budget.toMap();
    map['id'] = 1;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    if (existing.isNotEmpty) {
      await db.update(
        'accounting_budgets',
        map,
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      await db.insert(
        'accounting_budgets',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await _db.touchModified();
  }

  Future<List<AccountingRecord>> getAllRecords() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounting_records',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AccountingRecord.fromMap(maps[i]));
  }

  Future<List<AccountingRecord>> getRecordsByMonth(String yyyyMm) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounting_records',
      where: 'date LIKE ?',
      whereArgs: ['$yyyyMm%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AccountingRecord.fromMap(maps[i]));
  }

  Future<List<AccountingRecord>> getRecordsByDate(String date) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounting_records',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AccountingRecord.fromMap(maps[i]));
  }

  Future<List<AccountingRecord>> getRecordsByType(String type) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounting_records',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AccountingRecord.fromMap(maps[i]));
  }

  Future<void> insertRecord(AccountingRecord record) async {
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
      'accounting_records',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> deleteRecord(String id) async {
    final db = await _db.database;
    await db.delete(
      'accounting_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }
}
