import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/datasources/menu_remote_datasource.dart';
import 'package:mobileorder/data/datasources/store_remote_datasource.dart';

void main() {

  group('Real API Integration Tests - NO MOCKS', () {
    const testStoreId = '81898903-e31a-442a-9207-120e4a8f2a09';

    test('REAL API: Fetch store credentials and info', () async {
      print('\n🔥 Testing REAL Store Locator API...');
      final storeDataSource = StoreRemoteDataSource();

      // Step 1: Get credentials from locateStoreById
      print('Step 1: Calling locateStoreById with storeId: $testStoreId');
      final credentials = await storeDataSource.locateStoreById(testStoreId);

      print('✓ Credentials received:');
      print('  - appKey: ${credentials.appKey}');
      print('  - tenantId: ${credentials.tenantId}');
      print('  - deviceId: ${credentials.deviceId}');
      print('  - apiDomain: ${credentials.apiDomain}');

      expect(credentials.appKey, isNotEmpty, reason: 'appKey should not be empty');
      expect(credentials.appSecret, isNotEmpty, reason: 'appSecret should not be empty');
      expect(credentials.tenantId, isNotEmpty, reason: 'tenantId should not be empty');
      expect(credentials.deviceId, isNotEmpty, reason: 'deviceId should not be empty');
      expect(credentials.apiDomain, isNotEmpty, reason: 'apiDomain should not be empty');

      // Step 2: Get store info using credentials
      print('\nStep 2: Calling getStoreByDeviceNo with deviceNo: ${credentials.deviceId}');
      final storeInfoResponse = await storeDataSource.getStoreByDeviceNo(
        credentials: credentials,
        deviceNo: credentials.deviceId,
      );

      print('✓ Store info received:');
      print('  - result_code: ${storeInfoResponse.resultCode}');
      print('  - stores count: ${storeInfoResponse.storeInfos.length}');

      expect(storeInfoResponse.isSuccess, isTrue, reason: 'API should return success');
      expect(storeInfoResponse.storeInfos, isNotEmpty, reason: 'Should have at least one store');

      if (storeInfoResponse.storeInfos.isNotEmpty) {
        final store = storeInfoResponse.storeInfos.first;
        print('  - Store ID: ${store.storeId}');
        print('  - Store Name (EN): ${store.storeNameEn}');
        print('  - Store SN: ${store.storeSn}');
      }

      print('\n✅ Store Locator API Test PASSED\n');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('REAL API: Fetch menu categories', () async {
      print('\n🔥 Testing REAL Menu API (getMenu)...');

      // First get credentials
      final storeDataSource = StoreRemoteDataSource();
      final credentials = await storeDataSource.locateStoreById(testStoreId);
      final storeInfoResponse = await storeDataSource.getStoreByDeviceNo(
        credentials: credentials,
        deviceNo: credentials.deviceId,
      );

      expect(storeInfoResponse.storeInfos, isNotEmpty);
      final storeId = storeInfoResponse.storeInfos.first.storeId;

      // Now test menu API
      print('Step 1: Calling getMenu API...');
      print('  - storeId: $storeId');
      print('  - redeemable: 0');

      final menuDataSource = MenuRemoteDataSource();
      final menuResponse = await menuDataSource.getMenu(
        credentials: credentials,
        storeId: storeId,
      );

      print('✓ Menu response received:');
      print('  - result_code: ${menuResponse.resultCode}');
      print('  - desc: ${menuResponse.desc}');
      print('  - categories count: ${menuResponse.menu.length}');

      if (!menuResponse.isSuccess) {
        print('\n❌ ERROR: Menu API returned error code ${menuResponse.resultCode}');
        print('   Error description: ${menuResponse.desc}');
      }

      expect(menuResponse.isSuccess, isTrue, reason: 'Menu API should return success (got ${menuResponse.resultCode}: ${menuResponse.desc})');
      expect(menuResponse.menu, isNotEmpty, reason: 'Should have at least one category');

      // Print category details
      for (var i = 0; i < menuResponse.menu.length && i < 5; i++) {
        final category = menuResponse.menu[i];
        print('  Category ${i + 1}:');
        print('    - ID: ${category.id}');
        print('    - Name (EN): ${category.catNameEn}');
        print('    - Name (CN): ${category.catNameCn}');
        print('    - Parent ID: ${category.parentId}');
        print('    - Has Children: ${category.hasChildren}');
        print('    - Children count: ${category.child.length}');
      }

      print('\n✅ Menu API Test PASSED\n');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('REAL API: Fetch products by store', () async {
      print('\n🔥 Testing REAL Product API (getProductByStore)...');

      // First get credentials
      final storeDataSource = StoreRemoteDataSource();
      final credentials = await storeDataSource.locateStoreById(testStoreId);
      final storeInfoResponse = await storeDataSource.getStoreByDeviceNo(
        credentials: credentials,
        deviceNo: credentials.deviceId,
      );

      expect(storeInfoResponse.storeInfos, isNotEmpty);
      final storeId = storeInfoResponse.storeInfos.first.storeId;

      // Now test product API
      print('Step 1: Calling getProductByStore API...');
      print('  - storeId: $storeId');

      final menuDataSource = MenuRemoteDataSource();
      final productResponse = await menuDataSource.getProductByStore(
        credentials: credentials,
        storeId: storeId,
      );

      print('✓ Product response received:');
      print('  - result_code: ${productResponse.resultCode}');
      print('  - desc: ${productResponse.desc}');
      print('  - products count: ${productResponse.products.length}');

      if (!productResponse.isSuccess) {
        print('\n❌ ERROR: Product API returned error code ${productResponse.resultCode}');
        print('   Error description: ${productResponse.desc}');
      }

      expect(productResponse.isSuccess, isTrue, reason: 'Product API should return success (got ${productResponse.resultCode}: ${productResponse.desc})');
      expect(productResponse.products, isNotEmpty, reason: 'Should have at least one product');

      // Print product details
      for (var i = 0; i < productResponse.products.length && i < 5; i++) {
        final product = productResponse.products[i];
        print('  Product ${i + 1}:');
        print('    - ID: ${product.productId}');
        print('    - Name (EN): ${product.productNameEn}');
        print('    - Name (CN): ${product.productNameCn}');
        print('    - Price: ${product.formattedPrice}');
        print('    - Category ID: ${product.cateId}');
        print('    - Active: ${product.isActive}');
        print('    - Takeout Available: ${product.isTakeOutAvailable}');
        print('    - Has Modifiers: ${product.hasModifiersAvailable}');
      }

      print('\n✅ Product API Test PASSED\n');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
