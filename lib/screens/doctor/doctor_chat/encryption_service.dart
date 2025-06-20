import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static String generateKey() {
    final random = Random.secure();
    final key = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(key);
  }

  static String encryptMessage(String message, String keyString) {
    final key = Key.fromBase64(keyString);
    final encrypter = Encrypter(AES(key));
    final iv = IV.fromSecureRandom(16);

    final encrypted = encrypter.encrypt(message, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptMessage(String encryptedMessage, String keyString) {
    try {
      final parts = encryptedMessage.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted message format');

      final key = Key.fromBase64(keyString);
      final encrypter = Encrypter(AES(key));
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return 'Failed to decrypt message';
    }
  }
}