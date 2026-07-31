import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:minio/minio.dart';

class S3Service {
  final String bucket;
  final String endpoint;
  final String accessKey;
  final String secretKey;
  final String region;
  late final Minio _client;

  S3Service({
    this.bucket = '',
    this.endpoint = 's3.cstcloud.cn',
    this.accessKey = '',
    this.secretKey = '',
    this.region = 'us-east-1',
  }) {
    _client = Minio(
      endPoint: endpoint,
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: true,
      pathStyle: true,
      region: region,
    );
    debugPrint('S3Service (minio): endpoint=$endpoint, bucket=$bucket, region=$region');
  }

  Future<String> getObject(String key) async {
    try {
      final stream = await _client.getObject(bucket, key);
      final bytes = Uint8List.fromList(await stream.expand((e) => e).toList());
      final result = utf8.decode(bytes);
      debugPrint('S3 GET 成功: $key (${result.length} bytes)');
      return result;
    } on MinioS3Error catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final message = e.error?.code ?? e.toString();
      debugPrint('S3 GET 失败: statusCode=$statusCode, message=$message');
      throw S3Exception(statusCode, 'S3 访问失败: $message');
    } catch (e) {
      debugPrint('S3 GET 异常: ${e.runtimeType}: $e');
      throw Exception('网络错误: $e');
    }
  }

  Future<Uint8List> getObjectBytes(String key) async {
    try {
      final stream = await _client.getObject(bucket, key);
      final bytes = Uint8List.fromList(await stream.expand((e) => e).toList());
      debugPrint('S3 GET bytes 成功: $key (${bytes.length} bytes)');
      return bytes;
    } on MinioS3Error catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final message = e.error?.code ?? e.toString();
      debugPrint('S3 GET bytes 失败: statusCode=$statusCode, message=$message');
      throw S3Exception(statusCode, 'S3 访问失败: $message');
    } catch (e) {
      debugPrint('S3 GET bytes 异常: ${e.runtimeType}: $e');
      throw Exception('网络错误: $e');
    }
  }

  Future<void> putObject(String key, String content) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final etag = await _client.putObject(
        bucket,
        key,
        Stream<Uint8List>.value(bytes),
        size: bytes.length,
      );
      debugPrint('S3 PUT 成功: $key (${content.length} chars), etag=$etag');
    } on MinioS3Error catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final message = e.error?.code ?? e.toString();
      debugPrint('S3 PUT 失败: statusCode=$statusCode, message=$message');
      throw S3Exception(statusCode, 'S3 上传失败: $message');
    } catch (e) {
      debugPrint('S3 PUT 异常: ${e.runtimeType}: $e');
      throw Exception('网络错误: $e');
    }
  }

  Future<void> putObjectBytes(String key, Uint8List bytes) async {
    try {
      final etag = await _client.putObject(
        bucket,
        key,
        Stream<Uint8List>.value(bytes),
        size: bytes.length,
      );
      debugPrint('S3 PUT bytes 成功: $key (${bytes.length} bytes), etag=$etag');
    } on MinioS3Error catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final message = e.error?.code ?? e.toString();
      debugPrint('S3 PUT bytes 失败: statusCode=$statusCode, message=$message');
      throw S3Exception(statusCode, 'S3 上传失败: $message');
    } catch (e) {
      debugPrint('S3 PUT bytes 异常: ${e.runtimeType}: $e');
      throw Exception('网络错误: $e');
    }
  }

  Future<List<String>> listObjects({String? prefix}) async {
    try {
      final result = await _client.listAllObjects(
        bucket,
        prefix: prefix ?? '',
      );
      final keys = result.objects.map((obj) => obj.key!).toList();
      debugPrint('S3 LIST 成功: prefix=${prefix ?? "/"} (${keys.length} objects)');
      return keys;
    } on MinioS3Error catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final message = e.error?.code ?? e.toString();
      debugPrint('S3 LIST 失败: statusCode=$statusCode, message=$message');
      throw S3Exception(statusCode, 'S3 列出对象失败: $message');
    } catch (e) {
      debugPrint('S3 LIST 异常: ${e.runtimeType}: $e');
      throw Exception('网络错误: $e');
    }
  }

  Future<void> deleteObject(String key) async {
    try {
      await _client.removeObject(bucket, key);
      debugPrint('S3 DELETE 成功: $key');
    } on MinioS3Error catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final message = e.error?.code ?? e.toString();
      debugPrint('S3 DELETE 失败: statusCode=$statusCode, message=$message');
      throw S3Exception(statusCode, 'S3 删除失败: $message');
    } catch (e) {
      debugPrint('S3 DELETE 异常: ${e.runtimeType}: $e');
      throw Exception('网络错误: $e');
    }
  }

  void dispose() {
    // minio client doesn't need explicit disposal
  }
}

class S3Exception implements Exception {
  final int statusCode;
  final String message;
  S3Exception(this.statusCode, this.message);

  @override
  String toString() => 'S3Exception[$statusCode]: $message';
}