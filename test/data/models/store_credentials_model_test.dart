import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/models/store_credentials_model.dart';

void main() {
  group('StoreCredentialsModel', () {
    const testJson = {
      'appKey': 'testAppKey123',
      'appSecret': 'testAppSecret456',
      'tenantID': 'tenant789',
      'deviceID': 'device012',
      'apiDomain': 'https://api.example.com',
    };

    test('fromJson creates model from JSON', () {
      // Act
      final model = StoreCredentialsModel.fromJson(testJson);

      // Assert
      expect(model.appKey, equals('testAppKey123'));
      expect(model.appSecret, equals('testAppSecret456'));
      expect(model.tenantId, equals('tenant789'));
      expect(model.deviceId, equals('device012'));
      expect(model.apiDomain, equals('https://api.example.com'));
    });

    test('toJson converts model to JSON', () {
      // Arrange
      final model = StoreCredentialsModel(
        appKey: 'key1',
        appSecret: 'secret1',
        tenantId: 'tenant1',
        deviceId: 'device1',
        apiDomain: 'https://test.com',
      );

      // Act
      final json = model.toJson();

      // Assert
      expect(json['appKey'], equals('key1'));
      expect(json['appSecret'], equals('secret1'));
      expect(json['tenantID'], equals('tenant1'));
      expect(json['deviceID'], equals('device1'));
      expect(json['apiDomain'], equals('https://test.com'));
    });

    test('fromJson handles missing fields with defaults', () {
      // Arrange
      const incompleteJson = {
        'appKey': 'testKey',
      };

      // Act
      final model = StoreCredentialsModel.fromJson(incompleteJson);

      // Assert
      expect(model.appKey, equals('testKey'));
      expect(model.appSecret, equals('')); // Default value
      expect(model.tenantId, equals(''));
      expect(model.deviceId, equals(''));
      expect(model.apiDomain, equals(''));
    });

    test('toJsonString and fromJsonString work correctly', () {
      // Arrange
      final originalModel = StoreCredentialsModel(
        appKey: 'key1',
        appSecret: 'secret1',
        tenantId: 'tenant1',
        deviceId: 'device1',
        apiDomain: 'https://test.com',
      );

      // Act
      final jsonString = originalModel.toJsonString();
      final parsedModel = StoreCredentialsModel.fromJsonString(jsonString);

      // Assert
      expect(parsedModel.appKey, equals(originalModel.appKey));
      expect(parsedModel.appSecret, equals(originalModel.appSecret));
      expect(parsedModel.tenantId, equals(originalModel.tenantId));
      expect(parsedModel.deviceId, equals(originalModel.deviceId));
      expect(parsedModel.apiDomain, equals(originalModel.apiDomain));
    });

    test('toString includes key information', () {
      // Arrange
      final model = StoreCredentialsModel(
        appKey: 'key1',
        appSecret: 'secret1',
        tenantId: 'tenant1',
        deviceId: 'device1',
        apiDomain: 'https://test.com',
      );

      // Act
      final stringRepresentation = model.toString();

      // Assert
      expect(stringRepresentation, contains('key1'));
      expect(stringRepresentation, contains('tenant1'));
      expect(stringRepresentation, contains('device1'));
      expect(stringRepresentation, contains('https://test.com'));
    });

    test('fromJson handles integer values by converting to string', () {
      // Arrange - API sometimes returns integers instead of strings
      const jsonWithInts = {
        'appKey': 'testKey',
        'appSecret': 'testSecret',
        'tenantID': 1013, // Integer instead of string
        'deviceID': 'device123',
        'apiDomain': 'https://api.example.com',
      };

      // Act
      final model = StoreCredentialsModel.fromJson(jsonWithInts);

      // Assert
      expect(model.tenantId, equals('1013')); // Converted to string
      expect(model.appKey, equals('testKey'));
      expect(model.deviceId, equals('device123'));
    });

    test('fromJson handles all integer values', () {
      // Arrange - Extreme case where all values are integers
      const jsonAllInts = {
        'appKey': 123,
        'appSecret': 456,
        'tenantID': 789,
        'deviceID': 1011,
        'apiDomain': 1213,
      };

      // Act
      final model = StoreCredentialsModel.fromJson(jsonAllInts);

      // Assert
      expect(model.appKey, equals('123'));
      expect(model.appSecret, equals('456'));
      expect(model.tenantId, equals('789'));
      expect(model.deviceId, equals('1011'));
      expect(model.apiDomain, equals('1213'));
    });
  });
}
