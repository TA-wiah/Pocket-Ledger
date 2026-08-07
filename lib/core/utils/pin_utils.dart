import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PinUtils {
  PinUtils._();

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String pin, String salt, String expectedHash) {
    return hashPin(pin, salt) == expectedHash;
  }
}
