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

  // PBKDF2 function to derive a secure key
  static Uint8List _deriveKey(List<int> usernameBytes, List<int> saltBytes) {
    final hmac = Hmac(sha256, Uint8List.fromList(saltBytes)); // Using HMAC with SHA256
    return Uint8List.fromList(hmac.convert(usernameBytes).bytes);  // Convert bytes to Uint8List
  }

  static String encryptData(String data, String username) {
    // Derive key from username (Uint8List)
    final keyBytes = generateKeyFromUsername(username);

    // Ensure the key length is 16 bytes (128-bit key) for AES
    final key = encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, 16)));

    // Create an initialization vector (IV)
    final iv = encrypt.IV.fromLength(16);  // Generate a random IV of 16 bytes

    // Create the encrypter object with AES encryption algorithm and CBC mode
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(data, iv: iv);

    // Return the encrypted data as a Base64 string (along with the IV)
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