import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/models/store_info_model.dart';

void main() {
  group('StoreInfoResponse', () {
    test('fromJson parses API response correctly', () {
      // Arrange
      final jsonResponse = {
        'result_code': '200',
        'storeInfos': [
          {
            'store_id': 12,
            'store_sn': '003002',
            'store_note': '{"GST":"20-0409736-E","Images":{"Logo":"https://test.com/logo.png"}}',
            'store_name': '{"cn":"测试店","en":"Test Store"}',
            'street': 'Test Street',
            'contact_phone': '12345678',
          }
        ],
        'payTypeInfo': [],
        'saleTypeInfo': [],
        'desc': 'success',
      };

      // Act
      final response = StoreInfoResponse.fromJson(jsonResponse);

      // Assert
      expect(response.resultCode, equals('200'));
      expect(response.isSuccess, isTrue);
      expect(response.storeInfos.length, equals(1));
      expect(response.desc, equals('success'));
    });

    test('isSuccess returns true for result_code 200', () {
      // Arrange
      final response = StoreInfoResponse(
        resultCode: '200',
        storeInfos: [],
        payTypeInfo: [],
        saleTypeInfo: [],
      );

      // Act & Assert
      expect(response.isSuccess, isTrue);
    });

    test('isSuccess returns false for non-200 result_code', () {
      // Arrange
      final response = StoreInfoResponse(
        resultCode: '500',
        storeInfos: [],
        payTypeInfo: [],
        saleTypeInfo: [],
      );

      // Act & Assert
      expect(response.isSuccess, isFalse);
    });
  });

  group('StoreInfo', () {
    test('storeNameEn extracts English name from JSON', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{}',
        storeName: '{"cn":"咖啡店","en":"Coffee Shop"}',
      );

      // Act & Assert
      expect(storeInfo.storeNameEn, equals('Coffee Shop'));
    });

    test('storeNameEn falls back to Chinese if no English', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{}',
        storeName: '{"cn":"咖啡店"}',
      );

      // Act & Assert
      expect(storeInfo.storeNameEn, equals('咖啡店'));
    });

    test('storeNameEn handles invalid JSON gracefully', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{}',
        storeName: 'Plain Text Name',
      );

      // Act & Assert
      expect(storeInfo.storeNameEn, equals('Plain Text Name'));
    });

    test('brandColor extracts color from store_note', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{"LandingPage":{"TopBarColorCode":"#FF5733"}}',
        storeName: '{}',
      );

      // Act & Assert
      expect(storeInfo.brandColor, equals('#FF5733'));
    });

    test('brandColor returns default if not found', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{}',
        storeName: '{}',
      );

      // Act & Assert
      expect(storeInfo.brandColor, equals('#996600'));
    });

    test('logoUrl extracts logo URL from store_note', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{"Images":{"Logo":"https://example.com/logo.png"}}',
        storeName: '{}',
      );

      // Act & Assert
      expect(storeInfo.logoUrl, equals('https://example.com/logo.png'));
    });

    test('logoUrl returns null if not found', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{}',
        storeName: '{}',
      );

      // Act & Assert
      expect(storeInfo.logoUrl, isNull);
    });

    test('landingPageUrl extracts landing page URL from store_note', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: '{"Images":{"LandingPage":"https://example.com/landing.jpg"}}',
        storeName: '{}',
      );

      // Act & Assert
      expect(storeInfo.landingPageUrl, equals('https://example.com/landing.jpg'));
    });

    test('storeNoteData handles invalid JSON', () {
      // Arrange
      final storeInfo = StoreInfo(
        storeId: 1,
        storeSn: '001',
        storeNote: 'invalid json',
        storeName: '{}',
      );

      // Act & Assert
      expect(storeInfo.storeNoteData, equals({}));
    });
  });

  group('PayTypeInfo', () {
    test('fromJson creates model correctly', () {
      // Arrange
      final json = {
        'id': 60,
        'pay_name': 'Credit Card',
        'pay_code': '2013',
      };

      // Act
      final payType = PayTypeInfo.fromJson(json);

      // Assert
      expect(payType.id, equals(60));
      expect(payType.payName, equals('Credit Card'));
      expect(payType.payCode, equals('2013'));
    });
  });

  group('SaleTypeInfo', () {
    test('fromJson creates model correctly', () {
      // Arrange
      final json = {
        'id': 2,
        'sale_type_name': 'TAKE-OUT',
        'sale_type_code': '2009',
      };

      // Act
      final saleType = SaleTypeInfo.fromJson(json);

      // Assert
      expect(saleType.id, equals(2));
      expect(saleType.saleTypeName, equals('TAKE-OUT'));
      expect(saleType.saleTypeCode, equals('2009'));
    });

    test('fromJson handles numeric sale_type_code', () {
      // Arrange - API sometimes returns numeric codes
      final json = {
        'id': 7,
        'sale_type_name': 'DELIVERY',
        'sale_type_code': 2009,
      };

      // Act
      final saleType = SaleTypeInfo.fromJson(json);

      // Assert
      expect(saleType.saleTypeCode, equals('2009'));
    });
  });
}
