import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _keyStorageKey = 'encryption_key';
  static const _ivStorageKey = 'encryption_iv';

  late final enc.Key _key;
  late final enc.IV _iv;
  late final enc.Encrypter _encrypter;

  Future<void> _init() async {
    String? keyString = await _secureStorage.read(key: _keyStorageKey);
    String? ivString = await _secureStorage.read(key: _ivStorageKey);

    if (ivString == null) {
      _key = enc.Key.fromSecureRandom(32);
      _iv = enc.IV.fromSecureRandom(16);
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64.encode(_key.bytes),
      );
      await _secureStorage.write(
        key: _ivStorageKey,
        value: base64.encode(_iv.bytes),
      );
    } else {
      _key = enc.Key(base64.decode(keyString!));
      _iv = enc.IV(base64.decode(ivString));
    }
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  static Future<EncryptionService> create() async {
    final service = EncryptionService();
    await service._init();
    return service;
  }

  String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    try {
      final encrypted = enc.Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      return '';
    }
  }
}
