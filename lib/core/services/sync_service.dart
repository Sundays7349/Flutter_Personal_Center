import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 's3_service.dart';
import 'credential_storage.dart';

/// 同步状态枚举
enum SyncStatus {
  idle,           // 空闲
  syncing,        // 同步中
  success,        // 同步成功
  failed,         // 同步失败
  conflict,       // 有冲突
  offline,        // 离线
}

/// 同步结果
class SyncResult {
  final SyncStatus status;
  final String? message;
  final int? syncedRecords;

  SyncResult({
    required this.status,
    this.message,
    this.syncedRecords,
  });
}

/// 同步服务 - 单桶架构
///
/// 同步规则（基于“数据库最后修改时间”的全量同步）：
/// 1. 拉取云端 manifest，得到云端快照的时间戳
/// 2. 与本地数据库最后修改时间（sync_meta 表）比较
/// 3. 云端更新 → 下载云端快照，整库覆盖本地数据库
/// 4. 本地更新 → 将本地数据库整库导出上传为新的快照
/// 5. 时间一致 → 无需同步
class SyncService {
  final AppDatabase _db;
  final CredentialStorage _storage;
  final Future<String> Function() _getDeviceId;

  SyncService(
    this._db,
    this._storage,
    this._getDeviceId,
  );

  /// 获取当前用户名（用于构建 S3 路径）
  String? _getUsername() {
    return _storage.getUsername();
  }

  /// 获取用户 S3 路径前缀
  String _getUserPath() {
    final username = _getUsername();
    if (username == null || username.isEmpty) {
      throw Exception('未登录或用户信息缺失');
    }
    return 'users/$username';
  }

  /// 获取 S3 服务实例
  S3Service? _createS3Service() {
    final bucket = _storage.bucket;
    final accessKey = _storage.accessKey;
    final secretKey = _storage.secretKey;
    if (bucket == null || accessKey == null || secretKey == null) {
      return null;
    }
    return S3Service(
      bucket: bucket,
      accessKey: accessKey,
      secretKey: secretKey,
    );
  }

  /// 执行全量同步
  Future<SyncResult> fullSync() async {
    if (!_storage.isLoggedIn) {
      return SyncResult(status: SyncStatus.failed, message: '未登录');
    }

    final s3 = _createS3Service();
    if (s3 == null) {
      return SyncResult(status: SyncStatus.failed, message: 'S3 配置缺失');
    }

    try {
      final deviceId = await _getDeviceId();
      final userPath = _getUserPath();

      // 1. 获取本地数据库最后修改时间
      final localTime = await _db.getLastModified();
      debugPrint('=== 开始全量同步 === 本地最后修改时间: $localTime');

      // 2. 拉取云端 manifest（云端快照时间戳）
      final manifestKey = '$userPath/manifest.json';
      int remoteTime = 0;
      String? remoteFile;

      try {
        final manifestJson = await s3.getObject(manifestKey);
        final remoteManifest = json.decode(manifestJson) as Map<String, dynamic>;
        remoteTime = remoteManifest['version'] as int? ?? 0;
        remoteFile = remoteManifest['file_name'] as String?;
        debugPrint('云端最后修改时间: $remoteTime');
      } catch (e) {
        if (e is S3Exception && e.statusCode == 404) {
          debugPrint('云端 manifest 不存在，将创建新的同步');
        } else {
          rethrow;
        }
      }

      // 判断云端是否已有快照
      final bool hasCloudData = remoteTime > 0 && remoteFile != null;
      final bool hasLocalData = localTime > 0;

      if (!hasCloudData && hasLocalData) {
        // 3a. 云盘没有文件（首次同步）：直接上传本地数据库，建立云端基线
        await _uploadLocalSnapshot(s3, userPath, deviceId, localTime);
        await _markAllSynced();
        debugPrint('首次同步：云盘无文件，本地数据已上传云端');
      } else if (hasCloudData && !hasLocalData) {
        // 3b. 软件全新使用（本地无数据）：直接下载云端快照
        await _downloadAndReplaceLocal(s3, userPath, remoteFile, remoteTime);
        await _markAllSynced();
        debugPrint('首次使用：本地无数据，云端数据已下载覆盖本地');
      } else if (hasCloudData && remoteTime > localTime) {
        // 3c. 云端比本地新 → 下载快照并整库覆盖本地
        await _downloadAndReplaceLocal(s3, userPath, remoteFile, remoteTime);
        await _markAllSynced();
        debugPrint('云端数据已覆盖本地');
      } else if (hasLocalData && localTime > remoteTime) {
        // 3d. 本地比云端新 → 将本地数据库整库上传为新的快照
        await _uploadLocalSnapshot(s3, userPath, deviceId, localTime);
        await _markAllSynced();
        debugPrint('本地数据已上传云端');
      } else {
        // 3e. 本地与云端均无数据，或时间一致，无需同步
        debugPrint('本地与云端均无数据（$localTime），无需同步');
      }

      debugPrint('=== 全量同步完成 ===');
      return SyncResult(
        status: SyncStatus.success,
        message: '同步成功',
        syncedRecords: localTime,
      );
    } catch (e) {
      debugPrint('同步失败: $e');
      return SyncResult(status: SyncStatus.failed, message: '同步失败: $e');
    } finally {
      s3.dispose();
    }
  }

  /// 下载云端快照并整库覆盖本地数据库
  Future<void> _downloadAndReplaceLocal(
    S3Service s3,
    String userPath,
    String snapshotFileName,
    int remoteTime,
  ) async {
    final snapshotKey = '$userPath/$snapshotFileName';
    final snapshotBytes = await s3.getObjectBytes(snapshotKey);
    final snapshotJson = utf8.decode(gzip.decode(snapshotBytes));
    final remoteSnapshot = json.decode(snapshotJson) as Map<String, dynamic>;
    debugPrint('云端快照已下载: $snapshotFileName');

    await _replaceLocalFromSnapshot(remoteSnapshot, remoteTime);
  }

  /// 将本地数据库整库导出上传为新的快照
  Future<void> _uploadLocalSnapshot(
    S3Service s3,
    String userPath,
    String deviceId,
    int localTime,
  ) async {
    final localSnapshot = await _exportLocalSnapshot(deviceId, localTime);
    final snapshotFileName = 'v_$localTime.snapshot';
    final snapshotKey = '$userPath/$snapshotFileName';

    final snapshotJson = json.encode(localSnapshot);
    final compressedBytes = Uint8List.fromList(gzip.encode(utf8.encode(snapshotJson)));
    await s3.putObjectBytes(snapshotKey, compressedBytes);
    debugPrint('本地快照已上传: $snapshotKey');

    final newManifest = {
      'version': localTime,
      'updated_at': DateTime.fromMillisecondsSinceEpoch(localTime).toIso8601String(),
      'file_name': snapshotFileName,
      'file_size': compressedBytes.length,
      'devices': {
        deviceId: {
          'last_sync': localTime,
          'nickname': '当前设备',
        },
      },
    };
    await s3.putObject('$userPath/manifest.json', json.encode(newManifest));
    debugPrint('Manifest 已更新');

    // 清理旧快照（保留最近3个）
    await _cleanupOldSnapshots(s3, userPath, localTime);
  }

  /// 用云端快照整库覆盖本地数据库
  Future<void> _replaceLocalFromSnapshot(
    Map<String, dynamic> snapshot,
    int remoteTime,
  ) async {
    final db = await _db.database;
    final tables = snapshot['tables'] as Map<String, dynamic>? ?? const {};

    await db.transaction((txn) async {
      for (final table in AppDatabase.tableNames) {
        // 清空本地该表（以云端数据为准）
        await txn.delete(table);

        final records = tables[table] as List<dynamic>?;
        if (records == null || records.isEmpty) continue;

        for (final record in records) {
          final map = Map<String, dynamic>.from(record as Map);
          map['synced'] = 1;
          await txn.insert(
            table,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    // 覆盖后本地最后修改时间与云端保持一致
    await _db.setLastModified(remoteTime);
  }

  /// 导出本地数据为快照
  Future<Map<String, dynamic>> _exportLocalSnapshot(String deviceId, int version) async {
    final db = await _db.database;
    final tablesData = <String, dynamic>{};

    for (final table in AppDatabase.tableNames) {
      try {
        final List<Map<String, dynamic>> records = await db.query(table);
        if (records.isNotEmpty) {
          tablesData[table] = records;
        }
      } catch (e) {
        // 表可能不存在，跳过
        debugPrint('导出表 $table 失败: $e');
      }
    }

    return {
      'version': version,
      'exported_at': DateTime.fromMillisecondsSinceEpoch(version).toIso8601String(),
      'device_id': deviceId,
      'tables': tablesData,
    };
  }

  /// 标记所有记录为已同步
  Future<void> _markAllSynced() async {
    final db = await _db.database;
    for (final table in AppDatabase.tableNames) {
      try {
        await db.update(
          table,
          {'synced': 1},
          where: 'synced = 0',
        );
      } catch (e) {
        // 表可能不存在
        debugPrint('标记表 $table 已同步失败: $e');
      }
    }
  }

  /// 清理旧快照（保留最近3个）
  Future<void> _cleanupOldSnapshots(
    S3Service s3,
    String userPath,
    int currentVersion,
  ) async {
    try {
      final snapshots = await s3.listObjects(prefix: '$userPath/v_');
      // 按版本号排序
      snapshots.sort((a, b) {
        final va = int.tryParse(a.replaceAll('$userPath/v_', '').replaceAll('.snapshot', '')) ?? 0;
        final vb = int.tryParse(b.replaceAll('$userPath/v_', '').replaceAll('.snapshot', '')) ?? 0;
        return vb.compareTo(va);
      });

      // 删除超过3个的旧快照
      if (snapshots.length > 3) {
        final toDelete = snapshots.sublist(3);
        for (final key in toDelete) {
          await s3.deleteObject(key);
          debugPrint('删除旧快照: $key');
        }
      }
    } catch (e) {
      debugPrint('清理旧快照失败: $e');
    }
  }

  /// 获取同步状态
  Future<Map<String, dynamic>> getSyncStatus() async {
    final db = await _db.database;
    int totalRecords = 0;
    int unsyncedRecords = 0;

    for (final table in AppDatabase.tableNames) {
      try {
        final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        totalRecords += (countResult.first['count'] as int?) ?? 0;

        final unsyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $table WHERE synced = 0',
        );
        unsyncedRecords += (unsyncedResult.first['count'] as int?) ?? 0;
      } catch (e) {
        // 表可能不存在
      }
    }

    return {
      'total_records': totalRecords,
      'unsynced_records': unsyncedRecords,
      'is_synced': unsyncedRecords == 0,
      'last_sync': await _db.getLastModified(),
    };
  }
}
