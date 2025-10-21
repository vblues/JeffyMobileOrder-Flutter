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
    print('[Md5Helper] Signature input components:');
    print('[Md5Helper]   appKey: $appKey');
    print('[Md5Helper]   appSecret: $appSecret');
    print('[Md5Helper]   uri: $uri');
    print('[Md5Helper]   body length: ${body.length}');
    print('[Md5Helper]   timestamp: $timestamp');
    print('[Md5Helper] Full input: $input');
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    final signature = digest.toString();
    print('[Md5Helper] Generated signature: $signature');
    return signature;
  }

  /// Get current timestamp in seconds since epoch
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
