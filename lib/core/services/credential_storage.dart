import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CredentialStorage {
  static const _keyBucket = 's3_bucket';
  static const _keyAccessKey = 's3_access_key';
  static const _keySecretKey = 's3_secret_key';
  static const _keyLoggedIn = 's3_logged_in';
  static const _keyUsername = 's3_username';

  final SharedPreferences _prefs;

  CredentialStorage(this._prefs);

  Future<void> saveCredentials({
    required String bucket,
    required String accessKey,
    required String secretKey,
    String? username,
  }) async {
    await _prefs.setString(_keyBucket, bucket);
    await _prefs.setString(_keyAccessKey, accessKey);
    await _prefs.setString(_keySecretKey, secretKey);
    if (username != null) {
      await _prefs.setString(_keyUsername, username);
    }
    await _prefs.setBool(_keyLoggedIn, true);
  }

  String? get bucket => _prefs.getString(_keyBucket);
  String? get accessKey => _prefs.getString(_keyAccessKey);
  String? get secretKey => _prefs.getString(_keySecretKey);
  String? getUsername() => _prefs.getString(_keyUsername);
  bool get isLoggedIn => _prefs.getBool(_keyLoggedIn) ?? false;

  Future<void> clear() async {
    await _prefs.remove(_keyBucket);
    await _prefs.remove(_keyAccessKey);
    await _prefs.remove(_keySecretKey);
    await _prefs.remove(_keyLoggedIn);
    await _prefs.remove(_keyUsername);
  }
}

final credentialStorageProvider = FutureProvider<CredentialStorage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CredentialStorage(prefs);
});

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final storage = await ref.watch(credentialStorageProvider.future);
  return storage.isLoggedIn;
});

/// 当前登录用户名（用于替代固定昵称文案）
final usernameProvider = FutureProvider<String>((ref) async {
  final storage = await ref.watch(credentialStorageProvider.future);
  final name = storage.getUsername()?.trim();
  return (name == null || name.isEmpty) ? '用户' : name;
});

final s3CredentialsProvider = FutureProvider<Map<String, String>?>((ref) async {
  final storage = await ref.watch(credentialStorageProvider.future);
  if (!storage.isLoggedIn) return null;
  final bucket = storage.bucket;
  final accessKey = storage.accessKey;
  final secretKey = storage.secretKey;
  if (bucket == null || accessKey == null || secretKey == null) return null;
  return {
    'bucket': bucket,
    'accessKey': accessKey,
    'secretKey': secretKey,
  };
});
