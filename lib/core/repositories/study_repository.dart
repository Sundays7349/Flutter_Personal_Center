import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class StudyRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  StudyRepository(this._db, this._getDeviceId);

  Future<List<StudyPaper>> getAllPapers() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_papers',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => StudyPaper.fromMap(maps[i]));
  }

  Future<void> insertPaper(StudyPaper paper) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = paper.id.isEmpty ? const Uuid().v4() : paper.id;
    final map = paper.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'study_papers',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updatePaper(StudyPaper paper) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'study_papers',
      where: 'id = ?',
      whereArgs: [paper.id],
      limit: 1,
    );
    final map = paper.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'study_papers',
      map,
      where: 'id = ?',
      whereArgs: [paper.id],
    );
    await _db.touchModified();
  }

  Future<void> deletePaper(String id) async {
    final db = await _db.database;
    await db.delete(
      'study_papers',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<StudyExperiment>> getAllExperiments() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_experiments',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => StudyExperiment.fromMap(maps[i]));
  }

  Future<void> insertExperiment(StudyExperiment experiment) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = experiment.id.isEmpty ? const Uuid().v4() : experiment.id;
    final map = experiment.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'study_experiments',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateExperiment(StudyExperiment experiment) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'study_experiments',
      where: 'id = ?',
      whereArgs: [experiment.id],
      limit: 1,
    );
    final map = experiment.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'study_experiments',
      map,
      where: 'id = ?',
      whereArgs: [experiment.id],
    );
    await _db.touchModified();
  }

  Future<void> deleteExperiment(String id) async {
    final db = await _db.database;
    await db.delete(
      'study_experiments',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<StudyEnglish>> getAllEnglish() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_english',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => StudyEnglish.fromMap(maps[i]));
  }

  Future<List<StudyEnglish>> getEnglishByDate(String date) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_english',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => StudyEnglish.fromMap(maps[i]));
  }

  Future<void> insertEnglish(StudyEnglish english) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = english.id.isEmpty ? const Uuid().v4() : english.id;
    final map = english.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'study_english',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateEnglish(StudyEnglish english) async {
    final db = await _db.database;
    final now = DeviceInfo.nowTimestamp();
    final existing = await db.query(
      'study_english',
      where: 'id = ?',
      whereArgs: [english.id],
      limit: 1,
    );
    final map = english.toMap();
    if (existing.isNotEmpty) {
      map['created_at'] = existing.first['created_at'];
      map['device_id'] = existing.first['device_id'];
    }
    map['updated_at'] = now;
    map['synced'] = 0;
    await db.update(
      'study_english',
      map,
      where: 'id = ?',
      whereArgs: [english.id],
    );
    await _db.touchModified();
  }
}
