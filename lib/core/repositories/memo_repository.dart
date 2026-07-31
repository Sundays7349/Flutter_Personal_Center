import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class MemoRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  MemoRepository(this._db, this._getDeviceId);

  Future<List<MemoNote>> getAllNotes() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memo_notes',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => MemoNote.fromMap(maps[i]));
  }

  Future<void> insertNote(MemoNote note) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = note.id.isEmpty ? const Uuid().v4() : note.id;
    final map = note.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'memo_notes',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateNote(MemoNote note) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'memo_notes',
      where: 'id = ?',
      whereArgs: [note.id],
      limit: 1,
    );
    final map = note.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'memo_notes',
      map,
      where: 'id = ?',
      whereArgs: [note.id],
    );
    await _db.touchModified();
  }

  Future<void> deleteNote(String id) async {
    final db = await _db.database;
    await db.delete(
      'memo_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<MemoContact>> getAllContacts() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memo_contacts',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => MemoContact.fromMap(maps[i]));
  }

  Future<void> insertContact(MemoContact contact) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = contact.id.isEmpty ? const Uuid().v4() : contact.id;
    final map = contact.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'memo_contacts',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateContact(MemoContact contact) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'memo_contacts',
      where: 'id = ?',
      whereArgs: [contact.id],
      limit: 1,
    );
    final map = contact.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'memo_contacts',
      map,
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    await _db.touchModified();
  }

  Future<void> deleteContact(String id) async {
    final db = await _db.database;
    await db.delete(
      'memo_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<MemoShopping>> getAllShopping() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memo_shoppings',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => MemoShopping.fromMap(maps[i]));
  }

  Future<void> insertShopping(MemoShopping shopping) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = shopping.id.isEmpty ? const Uuid().v4() : shopping.id;
    final map = shopping.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'memo_shoppings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateShopping(MemoShopping shopping) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'memo_shoppings',
      where: 'id = ?',
      whereArgs: [shopping.id],
      limit: 1,
    );
    final map = shopping.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'memo_shoppings',
      map,
      where: 'id = ?',
      whereArgs: [shopping.id],
    );
    await _db.touchModified();
  }

  Future<void> deleteShopping(String id) async {
    final db = await _db.database;
    await db.delete(
      'memo_shoppings',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }
}
