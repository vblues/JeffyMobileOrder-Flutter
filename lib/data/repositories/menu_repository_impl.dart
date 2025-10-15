import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../datasources/menu_remote_datasource.dart';
import '../models/menu_model.dart';
import '../models/product_model.dart';
import '../models/store_credentials_model.dart';

class MenuRepository {
  final MenuRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  MenuRepository({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  /// Fetch menu categories with caching
  ///
  /// First tries to load from cache, then fetches from API if cache is stale
  /// Caches the result for future use
  Future<MenuResponse> getMenu({
    required StoreCredentialsModel credentials,
    required int storeId,
    bool forceRefresh = false,
  }) async {
    // Try to load from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedMenu = _getMenuFromCache();
      if (cachedMenu != null) {
        return cachedMenu;
      }
    }

    // Fetch from API
    final menuResponse = await remoteDataSource.getMenu(
      credentials: credentials,
      storeId: storeId,
    );

    // Cache the result if successful
    if (menuResponse.isSuccess) {
      await _cacheMenu(menuResponse);
    }

    return menuResponse;
  }

  /// Fetch products by store with caching
  ///
  /// First tries to load from cache, then fetches from API if cache is stale
  /// Caches the result for future use
  Future<ProductResponse> getProductByStore({
    required StoreCredentialsModel credentials,
    required int storeId,
    bool forceRefresh = false,
  }) async {
    // Try to load from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedProducts = _getProductsFromCache();
      if (cachedProducts != null) {
        return cachedProducts;
      }
    }

    // Fetch from API
    final productResponse = await remoteDataSource.getProductByStore(
      credentials: credentials,
      storeId: storeId,
    );

    // Cache the result if successful
    if (productResponse.isSuccess) {
      await _cacheProducts(productResponse);
    }

    return productResponse;
  }

  /// Get menu from cache
  MenuResponse? _getMenuFromCache() {
    try {
      final cachedJson = sharedPreferences.getString(StorageKeys.menu);
      if (cachedJson != null) {
        final data = json.decode(cachedJson) as Map<String, dynamic>;
        return MenuResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache menu data
  Future<void> _cacheMenu(MenuResponse menuResponse) async {
    try {
      final jsonData = {
        'result_code': menuResponse.resultCode,
        'menu': menuResponse.menu.map((category) => _categoryToJson(category)).toList(),
        'desc': menuResponse.desc,
      };
      await sharedPreferences.setString(
        StorageKeys.menu,
        json.encode(jsonData),
      );
    } catch (e) {
      // Cache save failed, continue without caching
    }
  }

  /// Convert MenuCategory to JSON (including nested children)
  Map<String, dynamic> _categoryToJson(MenuCategory category) {
    return {
      'id': category.id,
      'parent_id': category.parentId,
      'cat_name': category.catName,
      'category_sn': category.categorySn,
      'cat_pic': category.catPic,
      'cat_pic1': category.catPic1,
      'sort_sn': category.sortSn,
      'child': category.child.map((child) => _categoryToJson(child)).toList(),
    };
  }

  /// Get products from cache
  ProductResponse? _getProductsFromCache() {
    try {
      final cachedJson = sharedPreferences.getString(StorageKeys.productByStore);
      if (cachedJson != null) {
        final data = json.decode(cachedJson) as Map<String, dynamic>;
        return ProductResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache product data
  Future<void> _cacheProducts(ProductResponse productResponse) async {
    try {
      final jsonData = {
        'result_code': productResponse.resultCode,
        'products': productResponse.products.map((product) => _productToJson(product)).toList(),
        'desc': productResponse.desc,
      };
      await sharedPreferences.setString(
        StorageKeys.productByStore,
        json.encode(jsonData),
      );
    } catch (e) {
      // Cache save failed, continue without caching
    }
  }

  /// Convert Product to JSON
  Map<String, dynamic> _productToJson(Product product) {
    return {
      'status': product.status,
      'cid': product.cid,
      'cate_id': product.cateId,
      'product_pic': product.productPic,
      'product_id': product.productId,
      'product_name': product.productName,
      'note': product.note,
      'product_sn': product.productSn,
      'is_take_out': product.isTakeOut,
      'price': product.price,
      'sort_sn': product.sortSn,
      'start_time': product.startTime,
      'end_time': product.endTime,
      'ingredient_name': product.ingredientName,
      'ingredients_id': product.ingredientsId,
      'effective_start_time': product.effectiveStartTime,
      'effective_end_time': product.effectiveEndTime,
      'hasModifiers': product.hasModifiers,
    };
  }

  /// Clear menu cache
  Future<void> clearMenuCache() async {
    await sharedPreferences.remove(StorageKeys.menu);
    await sharedPreferences.remove(StorageKeys.productByStore);
  }
}
