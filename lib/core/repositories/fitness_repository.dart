import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';

class FitnessRepository {
  final AppDatabase _db;
  final Future<String> Function() _getDeviceId;

  FitnessRepository(this._db, this._getDeviceId);

  Future<List<FitnessWorkout>> getAllWorkouts() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_workouts',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => FitnessWorkout.fromMap(maps[i]));
  }

  Future<List<FitnessWorkout>> getWorkoutsByDate(String date) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_workouts',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => FitnessWorkout.fromMap(maps[i]));
  }

  Future<void> insertWorkout(FitnessWorkout workout) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = workout.id.isEmpty ? const Uuid().v4() : workout.id;
    final map = workout.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'fitness_workouts',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> deleteWorkout(String id) async {
    final db = await _db.database;
    await db.delete(
      'fitness_workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<FitnessBody>> getAllBodies() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_bodies',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => FitnessBody.fromMap(maps[i]));
  }

  Future<FitnessBody?> getLatestBody() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_bodies',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FitnessBody.fromMap(maps.first);
  }

  Future<void> insertBody(FitnessBody body) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = body.id.isEmpty ? const Uuid().v4() : body.id;
    final map = body.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'fitness_bodies',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> deleteBody(String id) async {
    final db = await _db.database;
    await db.delete(
      'fitness_bodies',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }

  Future<List<FitnessDiet>> getAllDiets() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_diets',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => FitnessDiet.fromMap(maps[i]));
  }

  Future<List<FitnessDiet>> getDietsByDate(String date) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_diets',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => FitnessDiet.fromMap(maps[i]));
  }

  Future<void> insertDiet(FitnessDiet diet) async {
    final db = await _db.database;
    final deviceId = await _getDeviceId();
    final now = DeviceInfo.nowTimestamp();
    final id = diet.id.isEmpty ? const Uuid().v4() : diet.id;
    final map = diet.toMap();
    map['id'] = id;
    map['created_at'] = now;
    map['updated_at'] = now;
    map['device_id'] = deviceId;
    map['synced'] = 0;
    await db.insert(
      'fitness_diets',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.touchModified();
  }

  Future<void> updateDiet(FitnessDiet diet) async {
    await insertDiet(diet);
  }

  Future<void> deleteDiet(String id) async {
    final db = await _db.database;
    await db.delete(
      'fitness_diets',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.touchModified();
  }
}
