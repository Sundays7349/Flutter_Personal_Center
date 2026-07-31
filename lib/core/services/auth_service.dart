import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 's3_service.dart';
import 'credential_storage.dart';

class AuthService {
  static const String salt = 'SyuctIntegratedMediaCenterVideoDepartment';

  final CredentialStorage _storage;

  AuthService(this._storage);

  Future<void> login({
    required String username,
    required String password,
    required String bucket,
    required String accessKey,
    required String secretKey,
  }) async {
    final s3 = S3Service(
      bucket: bucket,
      accessKey: accessKey,
      secretKey: secretKey,
    );

    // Download user.json from S3 bucket root
    final String jsonString;
    try {
      jsonString = await s3.getObject('user.json');
      debugPrint('===== user.json 下载成功 =====');
      debugPrint('内容长度: ${jsonString.length}');
      debugPrint('内容: "$jsonString"');
      debugPrint('Codes: ${jsonString.codeUnits}');
      debugPrint('===============================');
      if (jsonString.isEmpty) {
        throw Exception('user.json 文件为空，请检查 S3 上的文件内容');
      }
    } on S3Exception catch (e) {
      if (e.statusCode == 404) {
        throw Exception('配置文件不存在 (user.json)，请检查桶名和权限');
      }
      throw Exception('S3 访问失败: ${e.toString()}');
    } catch (e) {
      throw Exception('网络错误: $e');
    }

    // Parse JSON
    final Map<String, dynamic> userData;
    try {
      userData = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('user.json 格式错误');
    }

    final storedUsername = userData['username'] as String?;
    final storedPassword = userData['password'] as String?;

    if (storedUsername == null || storedPassword == null) {
      throw Exception('user.json 缺少必要字段');
    }

    if (storedUsername != username) {
      throw Exception('用户不存在');
    }

    // Verify password (MD5(password + salt))
    final hashedPassword = _md5('$password$salt');
    if (hashedPassword != storedPassword.toLowerCase()) {
      throw Exception('密码不正确');
    }

    // Save credentials
    await _storage.saveCredentials(
      bucket: bucket,
      accessKey: accessKey,
      secretKey: secretKey,
      username: username,
    );
  }

  String _md5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}

final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final storage = await ref.watch(credentialStorageProvider.future);
  return AuthService(storage);
});
