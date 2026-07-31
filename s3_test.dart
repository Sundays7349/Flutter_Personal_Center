// 验证 user.json 中密码的实际格式
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  const storedPassword =
      'cXdlcnR5MTIzLlN5dWN0SW50ZWdyatedlNlZGlhQ2VudGVyVmlkZW9EZXBhcnRtZW50';
  const salt = 'SyuctIntegratedMediaCenterVideoDepartment';

  print('存储的密码: $storedPassword');
  print('');

  // 2. 模拟几个常见密码的 MD5
  const testPasswords = ['qwerty123.', '123456', 'admin', '12345678'];
  for (final pwd in testPasswords) {
    final combined = '$pwd$salt';
    final hash = md5.convert(utf8.encode(combined)).toString();
    final b64Plain = base64.encode(utf8.encode(combined));
    final b64Hash = base64.encode(md5.convert(utf8.encode(combined)).bytes);
    print('密码: $pwd');
    print('  MD5(密码+盐) = $hash');
    print('  Base64(密码+盐) = $b64Plain');
    print('  Base64(MD5字节) = $b64Hash');
    print('');
  }

  // 3. 对比
  print('=== 对比 ===');
  final testPwd = 'password123';
  final combined = '$testPwd$salt';

  final md5Hex = md5.convert(utf8.encode(combined)).toString();
  final b64Plain = base64.encode(utf8.encode(combined));
  final b64Hash = base64.encode(md5.convert(utf8.encode(combined)).bytes);

  print('存储值:   $storedPassword');
  print('');
  print('MD5 hex:  $md5Hex  (长度=${md5Hex.length})');
  print('Base64明文: $b64Plain  (长度=${b64Plain.length})');
  print('Base64MD5: $b64Hash  (长度=${b64Hash.length})');
  print('');
  print('与存储值匹配?');
  print('  MD5 hex 匹配: ${md5Hex == storedPassword.toLowerCase()}');
  print('  Base64明文匹配: ${b64Plain == storedPassword}');
  print('  Base64MD5 匹配: ${b64Hash == storedPassword}');
}