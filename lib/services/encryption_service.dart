import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  final String _uid;
  late final enc.Key _key;
  late final enc.IV _iv;
  late final enc.Encrypter _encrypter;

  EncryptionService(this._uid) {
    _init();
  }

  void _init() {
    // Combine UID with a global secret from .env for key derivation
    String globalSecret;
    try {
      globalSecret =
          dotenv.env['ENCRYPTION_SECRET'] ?? 'fallback_memora_secret_key_32chars';
    } catch (e) {
      // If dotenv is not initialized (e.g., .env file is missing), use a fallback.
      globalSecret = 'fallback_memora_secret_key_32chars';
    }

    // Create a 32-byte key using SHA-256
    final keySeed = '$_uid$globalSecret';
    final keyHash = sha256.convert(utf8.encode(keySeed)).bytes;
    _key = enc.Key(Uint8List.fromList(keyHash));

    // Create a 16-byte IV using MD5 (or just take part of SHA-256)
    final ivHash = md5.convert(utf8.encode(keySeed)).bytes;
    _iv = enc.IV(Uint8List.fromList(ivHash));

    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      return '';
    }
  }

  String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    try {
      final encrypted = enc.Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      return '';
    }
  }
}
