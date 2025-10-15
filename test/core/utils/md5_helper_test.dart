import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/core/utils/md5_helper.dart';

void main() {
  group('Md5Helper', () {
    test('generateSignature creates correct MD5 hash', () {
      // Arrange
      const appKey = 'testAppKey';
      const appSecret = 'testAppSecret';
      const uri = 'api/mobile/getStoreByDeviceNo';
      const body = '{"deviceNo":"test123"}';
      const timestamp = 1697356800;

      // Act
      final signature = Md5Helper.generateSignature(
        appKey: appKey,
        appSecret: appSecret,
        uri: uri,
        body: body,
        timestamp: timestamp,
      );

      // Assert
      expect(signature, isNotEmpty);
      expect(signature.length, equals(32)); // MD5 hash is 32 characters
      expect(signature, matches(RegExp(r'^[a-f0-9]{32}$'))); // Lowercase hex
    });

    test('generateSignature produces consistent results', () {
      // Arrange
      const appKey = 'testKey';
      const appSecret = 'testSecret';
      const uri = 'test/uri';
      const body = '{"test":"data"}';
      const timestamp = 1234567890;

      // Act
      final signature1 = Md5Helper.generateSignature(
        appKey: appKey,
        appSecret: appSecret,
        uri: uri,
        body: body,
        timestamp: timestamp,
      );

      final signature2 = Md5Helper.generateSignature(
        appKey: appKey,
        appSecret: appSecret,
        uri: uri,
        body: body,
        timestamp: timestamp,
      );

      // Assert
      expect(signature1, equals(signature2));
    });

    test('generateSignature changes with different inputs', () {
      // Arrange
      const appKey = 'testKey';
      const appSecret = 'testSecret';
      const uri = 'test/uri';
      const body1 = '{"test":"data1"}';
      const body2 = '{"test":"data2"}';
      const timestamp = 1234567890;

      // Act
      final signature1 = Md5Helper.generateSignature(
        appKey: appKey,
        appSecret: appSecret,
        uri: uri,
        body: body1,
        timestamp: timestamp,
      );

      final signature2 = Md5Helper.generateSignature(
        appKey: appKey,
        appSecret: appSecret,
        uri: uri,
        body: body2,
        timestamp: timestamp,
      );

      // Assert
      expect(signature1, isNot(equals(signature2)));
    });

    test('getCurrentTimestamp returns valid Unix timestamp', () {
      // Act
      final timestamp = Md5Helper.getCurrentTimestamp();

      // Assert
      expect(timestamp, greaterThan(1600000000)); // After 2020
      expect(timestamp, lessThan(2000000000)); // Before 2033
    });
  });
}
