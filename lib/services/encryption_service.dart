import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class KeyPair {
  final String publicKey;
  final String privateKey;

  KeyPair({required this.publicKey, required this.privateKey});
}

class EncryptionService {
  // Generate RSA key pair for asymmetric encryption
  static KeyPair generateKeyPair() {
    // Placeholder: return empty strings to avoid RSA key generation complexity here
    return KeyPair(publicKey: '', privateKey: '');
  }

  // Encrypt message with recipient's public key
  static String encryptMessage(String message, String publicKey) {
    // Placeholder: base64-encode only (not secure). Replace with real RSA.
    return base64.encode(utf8.encode(message));
  }

  // Decrypt message with private key
  static String decryptMessage(String encryptedMessage, String privateKey) {
    // Placeholder: base64-decode only
    return utf8.decode(base64.decode(encryptedMessage));
  }

  // Generate symmetric key for individual messages
  static String generateSymmetricKey() {
    final key = Key.fromSecureRandom(32);
    return key.base64;
  }

  // Symmetric encryption for message content
  static String symmetricEncrypt(String plainText, String keyBase64) {
    final key = Key.fromBase64(keyBase64);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String symmetricDecrypt(String encryptedText, String keyBase64) {
    final parts = encryptedText.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final key = Key.fromBase64(keyBase64);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
