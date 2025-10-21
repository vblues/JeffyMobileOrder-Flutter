import 'dart:convert';
import 'package:crypto/crypto.dart';

class Md5Helper {
  /// Generate MD5 hash for API signature
  /// Formula: MD5(appKey + appSecret + uri + body + timestamp)
  static String generateSignature({
    required String appKey,
    required String appSecret,
    required String uri,
    required String body,
    required int timestamp,
  }) {
    final String input = '$appKey$appSecret$uri$body$timestamp';
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    final signature = digest.toString();
    return signature;
  }

  /// Get current timestamp in seconds since epoch
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
