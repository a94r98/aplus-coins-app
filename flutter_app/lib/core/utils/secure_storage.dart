import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  static const String _tokenKey = 'jwt_auth_token';
  static const String _fingerprintKey = 'device_fingerprint';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<String> getDeviceFingerprint() async {
    try {
      String? fp = await _storage.read(key: _fingerprintKey);
      if (fp == null) {
        final rand = Random();
        final randomVal = List.generate(16, (index) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
        fp = 'fp-${DateTime.now().millisecondsSinceEpoch}-$randomVal';
        await _storage.write(key: _fingerprintKey, value: fp);
      }
      return fp;
    } catch (_) {
      return 'fp-fallback-device';
    }
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    await _storage.write(key: 'notifications_enabled', value: enabled ? 'true' : 'false');
  }

  static Future<bool> getNotificationsEnabled() async {
    final val = await _storage.read(key: 'notifications_enabled');
    return val != 'false'; // default to true
  }
}
