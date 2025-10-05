import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static final _storage = const FlutterSecureStorage();

  static Future<void> writeToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }

  static Future<void> writeUsername(String username) async {
    await _storage.write(key: 'username', value: username);
  }

  static Future<String?> readUsername() async {
    return await _storage.read(key: 'username');
  }

  static Future<void> deleteUsername() async {
    await _storage.delete(key: 'username');
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
