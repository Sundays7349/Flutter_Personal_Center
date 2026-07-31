import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class ShootingRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  ShootingRepository(this._db, this._getDeviceId);

  Future<List<ShootingProject>> getAllProjects({bool? done}) async {
    final db = await _db.database;
    final where = done == null ? null : 'done = ?';
    final whereArgs = done == null ? null : [done ? 1 : 0];
    final List<Map<String, dynamic>> maps = await db.query(
      'shooting_projects',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => ShootingProject.fromMap(maps[i]));
  }

  Future<void> insertProject(ShootingProject p) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = p.id.isEmpty ? const Uuid().v4() : p.id;
    final map = p.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'shooting_projects',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateProject(ShootingProject p) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'shooting_projects',
      where: 'id = ?',
      whereArgs: [p.id],
      limit: 1,
    );
    final map = p.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'shooting_projects',
      map,
      where: 'id = ?',
      whereArgs: [p.id],
    );
    await _db.touchModified();
  }

  Future<void> deleteProject(String id) async {
    final db = await _db.database;
    await db.delete(
      'shooting_projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<ShootingIdea>> getAllIdeas() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shooting_ideas',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => ShootingIdea.fromMap(maps[i]));
  }

  Future<void> insertIdea(ShootingIdea i) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = i.id.isEmpty ? const Uuid().v4() : i.id;
    final map = i.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'shooting_ideas',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> deleteIdea(String id) async {
    final db = await _db.database;
    await db.delete(
      'shooting_ideas',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }
}
