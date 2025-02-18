import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class KeyGenerator {
  static Uint8List generateKeyFromUsername(String username) {
    final salt = 'b00f7c904c89a2a9e19cf754d67c7f56741c001f6ad1ebced108946e6d961d5e';

    final usernameBytes = utf8.encode(username);
    final saltBytes = utf8.encode(salt);

    final key = _deriveKey(usernameBytes, saltBytes);

    return key;
  }

  static Uint8List _deriveKey(List<int> usernameBytes, List<int> saltBytes) {
    final hmac = Hmac(sha256, Uint8List.fromList(saltBytes));
    return Uint8List.fromList(hmac.convert(usernameBytes).bytes);
  }

  static String encryptData(String data, String username) {
    final keyBytes = generateKeyFromUsername(username);
    final key = encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, 16)));
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);

    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decryptData(String encryptedData, String username) {
    final keyBytes = generateKeyFromUsername(username);

    final key = encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, 16)));

    final parts = encryptedData.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedText = parts[1];

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);

    return decrypted;
  }


}