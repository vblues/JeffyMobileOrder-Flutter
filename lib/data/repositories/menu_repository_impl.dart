import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../datasources/menu_remote_datasource.dart';
import '../models/menu_model.dart';
import '../models/product_model.dart';
import '../models/product_attribute_model.dart';
import '../models/combo_model.dart';
import '../models/store_credentials_model.dart';

class MenuRepository {
  final MenuRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  MenuRepository({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  /// Cache expiration duration (15 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 15);

  /// Generate store-specific cache key
  String _getStoreSpecificKey(String baseKey, int storeId) {
    return '${baseKey}_$storeId';
  }

  /// Check if cached data is still valid (not expired)
  bool _isCacheValid(int? cachedTimestamp) {
    if (cachedTimestamp == null) return false;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
    final now = DateTime.now();
    final age = now.difference(cachedTime);

    return age < _cacheExpiration;
  }

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
      final cachedMenu = _getMenuFromCache(storeId);
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
      await _cacheMenu(menuResponse, storeId);
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
      final cachedProducts = _getProductsFromCache(storeId);
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
      await _cacheProducts(productResponse, storeId);
    }

    return productResponse;
  }

  /// Fetch product attributes (modifiers) with caching
  ///
  /// First tries to load from cache, then fetches from API if cache is stale
  /// Caches the result for future use
  Future<ProductAttributeResponse> getProductAtt({
    required StoreCredentialsModel credentials,
    required int storeId,
    bool forceRefresh = false,
  }) async {
    // Try to load from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedAttributes = _getProductAttFromCache(storeId);
      if (cachedAttributes != null) {
        return cachedAttributes;
      }
    }

    // Fetch from API
    final attributeResponse = await remoteDataSource.getProductAtt(
      credentials: credentials,
      storeId: storeId,
    );

    // Cache the result if successful
    if (attributeResponse.resultCode == 200) {
      await _cacheProductAtt(attributeResponse, storeId);
    }

    return attributeResponse;
  }

  /// Fetch combo activities with pricing with caching
  ///
  /// First tries to load from cache, then fetches from API if cache is stale
  /// Caches the result for future use
  Future<ComboActivityResponse> getActivityComboWithPrice({
    required StoreCredentialsModel credentials,
    required int storeId,
    bool forceRefresh = false,
  }) async {
    // Try to load from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedActivities = _getComboActivitiesFromCache(storeId);
      if (cachedActivities != null) {
        return cachedActivities;
      }
    }

    // Fetch from API
    final comboResponse = await remoteDataSource.getActivityComboWithPrice(
      credentials: credentials,
      storeId: storeId,
    );

    // Cache the result if successful
    if (comboResponse.resultCode == 200) {
      await _cacheComboActivities(comboResponse, storeId);
    }

    return comboResponse;
  }

  /// Fetch store combo products with caching
  ///
  /// First tries to load from cache, then fetches from API if cache is stale
  /// Caches the result for future use
  Future<ProductResponse> getStoreComboProduct({
    required StoreCredentialsModel credentials,
    required int storeId,
    bool forceRefresh = false,
  }) async {
    // Try to load from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedComboProducts = _getComboProductsFromCache(storeId);
      if (cachedComboProducts != null) {
        return cachedComboProducts;
      }
    }

    // Fetch from API
    final productResponse = await remoteDataSource.getStoreComboProduct(
      credentials: credentials,
      storeId: storeId,
    );

    // Cache the result if successful
    if (productResponse.isSuccess) {
      await _cacheComboProducts(productResponse, storeId);
    }

    return productResponse;
  }

  /// Get menu from cache
  MenuResponse? _getMenuFromCache(int storeId) {
    try {
      final cacheKey = _getStoreSpecificKey(StorageKeys.menu, storeId);
      final cachedJson = sharedPreferences.getString(cacheKey);
      if (cachedJson != null) {
        final wrapper = json.decode(cachedJson) as Map<String, dynamic>;

        // Check if cache is still valid
        final timestamp = wrapper['timestamp'] as int?;
        if (!_isCacheValid(timestamp)) {
          return null; // Cache expired
        }

        // Extract and return the data
        final data = wrapper['data'] as Map<String, dynamic>;
        return MenuResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache menu data
  /// Only overwrites existing cache if data is successfully encoded
  Future<void> _cacheMenu(MenuResponse menuResponse, int storeId) async {
    try {
      final jsonData = {
        'result_code': menuResponse.resultCode,
        'menu': menuResponse.menu.map((category) => _categoryToJson(category)).toList(),
        'desc': menuResponse.desc,
      };

      // Wrap data with timestamp
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': jsonData,
      };

      // Try to encode JSON - will throw if invalid
      final encodedJson = json.encode(wrapper);

      // Only save if encoding succeeded
      final cacheKey = _getStoreSpecificKey(StorageKeys.menu, storeId);
      await sharedPreferences.setString(cacheKey, encodedJson);
    } catch (e) {
      // Cache save failed (invalid JSON or encoding error)
      // Don't overwrite existing cache
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
  ProductResponse? _getProductsFromCache(int storeId) {
    try {
      final cacheKey = _getStoreSpecificKey(StorageKeys.productByStore, storeId);
      final cachedJson = sharedPreferences.getString(cacheKey);
      if (cachedJson != null) {
        final wrapper = json.decode(cachedJson) as Map<String, dynamic>;

        // Check if cache is still valid
        final timestamp = wrapper['timestamp'] as int?;
        if (!_isCacheValid(timestamp)) {
          return null; // Cache expired
        }

        // Extract and return the data
        final data = wrapper['data'] as Map<String, dynamic>;
        return ProductResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache product data
  /// Only overwrites existing cache if data is successfully encoded
  Future<void> _cacheProducts(ProductResponse productResponse, int storeId) async {
    try {
      final jsonData = {
        'result_code': productResponse.resultCode,
        'products': productResponse.products.map((product) => _productToJson(product)).toList(),
        'desc': productResponse.desc,
      };

      // Wrap data with timestamp
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': jsonData,
      };

      // Try to encode JSON - will throw if invalid
      final encodedJson = json.encode(wrapper);

      // Only save if encoding succeeded
      final cacheKey = _getStoreSpecificKey(StorageKeys.productByStore, storeId);
      await sharedPreferences.setString(cacheKey, encodedJson);
    } catch (e) {
      // Cache save failed (invalid JSON or encoding error)
      // Don't overwrite existing cache
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

  /// Get product attributes from cache
  ProductAttributeResponse? _getProductAttFromCache(int storeId) {
    try {
      final cacheKey = _getStoreSpecificKey(StorageKeys.productAtt, storeId);
      final cachedJson = sharedPreferences.getString(cacheKey);
      if (cachedJson != null) {
        final wrapper = json.decode(cachedJson) as Map<String, dynamic>;

        // Check if cache is still valid
        final timestamp = wrapper['timestamp'] as int?;
        if (!_isCacheValid(timestamp)) {
          return null; // Cache expired
        }

        // Extract and return the data
        final data = wrapper['data'] as Map<String, dynamic>;
        return ProductAttributeResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache product attributes data
  /// Only overwrites existing cache if data is successfully encoded
  Future<void> _cacheProductAtt(ProductAttributeResponse attributeResponse, int storeId) async {
    try {
      // Note: This can be large (~6MB according to docs)
      // Consider implementing compression or selective caching if needed
      final jsonData = {
        'result_code': attributeResponse.resultCode,
        'atts': attributeResponse.attributes.map((group) => _attributeGroupToJson(group)).toList(),
        'desc': attributeResponse.description,
      };

      // Wrap data with timestamp
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': jsonData,
      };

      // Try to encode JSON - will throw if invalid
      final encodedJson = json.encode(wrapper);

      // Only save if encoding succeeded
      final cacheKey = _getStoreSpecificKey(StorageKeys.productAtt, storeId);
      await sharedPreferences.setString(cacheKey, encodedJson);
    } catch (e) {
      // Cache save failed (invalid JSON, encoding error, or possibly too large)
      // Don't overwrite existing cache
    }
  }

  /// Convert ProductAttributeGroup to JSON
  Map<String, dynamic> _attributeGroupToJson(ProductAttributeGroup group) {
    return {
      'product_id': group.productId,
      'product_type': group.productType,
      'atts': group.attributes.map((att) => _attributeToJson(att)).toList(),
    };
  }

  /// Convert ProductAttribute to JSON
  Map<String, dynamic> _attributeToJson(ProductAttribute att) {
    return {
      'att_id': att.attId,
      'attr_sn': att.attrSn,
      'att_name': att.attName,
      'multi_select': att.multiSelect,
      'min_num': att.minNum,
      'max_num': att.maxNum,
      'sort': att.sort,
      'att_val_info': att.values.map((val) => _attributeValueToJson(val)).toList(),
    };
  }

  /// Convert AttributeValue to JSON
  Map<String, dynamic> _attributeValueToJson(AttributeValue val) {
    return {
      'att_val_name': val.attValName,
      'att_val_id': val.attValId,
      'price': val.price,
      'default_choose': val.defaultChoose,
      'att_val_sn': val.attValSn,
      'min_num': val.minNum,
      'max_num': val.maxNum,
      'sort': val.sort,
    };
  }

  /// Get combo activities from cache
  ComboActivityResponse? _getComboActivitiesFromCache(int storeId) {
    try {
      final cacheKey = _getStoreSpecificKey(StorageKeys.comboActivities, storeId);
      final cachedJson = sharedPreferences.getString(cacheKey);
      if (cachedJson != null) {
        final wrapper = json.decode(cachedJson) as Map<String, dynamic>;

        // Check if cache is still valid
        final timestamp = wrapper['timestamp'] as int?;
        if (!_isCacheValid(timestamp)) {
          return null; // Cache expired
        }

        // Extract and return the data
        final data = wrapper['data'] as Map<String, dynamic>;
        return ComboActivityResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache combo activities data
  /// Only overwrites existing cache if data is successfully encoded
  Future<void> _cacheComboActivities(ComboActivityResponse comboResponse, int storeId) async {
    try {
      // Store as JSON directly - the model already handles serialization
      final jsonData = {
        'result_code': comboResponse.resultCode,
        'data': comboResponse.activities.map((activity) => _comboActivityToJson(activity)).toList(),
        'desc': comboResponse.desc,
      };

      // Wrap data with timestamp
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': jsonData,
      };

      // Try to encode JSON - will throw if invalid
      final encodedJson = json.encode(wrapper);

      // Only save if encoding succeeded
      final cacheKey = _getStoreSpecificKey(StorageKeys.comboActivities, storeId);
      await sharedPreferences.setString(cacheKey, encodedJson);
    } catch (e) {
      // Cache save failed (invalid JSON or encoding error)
      // Don't overwrite existing cache
    }
  }

  /// Convert ComboActivity to JSON
  Map<String, dynamic> _comboActivityToJson(ComboActivity activity) {
    return {
      'activity_combo_id': activity.activityComboId,
      'activity_sn': activity.activitySn,
      'activity_name': activity.activityName,
      'activity_pic': activity.activityPic,
      'discount_sn': activity.discountSn,
      'discount_type': activity.discountType,
      'discount_num': activity.discountNum,
      'start_time': activity.startTime,
      'end_time': activity.endTime,
      'act_cycle_daytime': activity.actCycleDaytime,
      'cdata': activity.categories.map((cat) => _comboCategoryToJson(cat)).toList(),
    };
  }

  /// Convert ComboCategory to JSON
  Map<String, dynamic> _comboCategoryToJson(ComboCategory category) {
    return {
      'type_name': category.typeName,
      'min_num': category.minNum,
      'max_num': category.maxNum,
      'type_name_sn': category.typeNameSn,
      'is_choice': category.isChoice,
      'sort': category.sort,
      'product_id': category.productIds.map((p) => _comboProductInfoToJson(p)).toList(),
      'default_id': category.defaultIds,
    };
  }

  /// Convert ComboProductInfo to JSON
  Map<String, dynamic> _comboProductInfoToJson(ComboProductInfo productInfo) {
    return {
      'product_id': productInfo.productId,
      'product_price': productInfo.productPrice,
    };
  }

  /// Get combo products from cache
  ProductResponse? _getComboProductsFromCache(int storeId) {
    try {
      final cacheKey = _getStoreSpecificKey(StorageKeys.comboProducts, storeId);
      final cachedJson = sharedPreferences.getString(cacheKey);
      if (cachedJson != null) {
        final wrapper = json.decode(cachedJson) as Map<String, dynamic>;

        // Check if cache is still valid
        final timestamp = wrapper['timestamp'] as int?;
        if (!_isCacheValid(timestamp)) {
          return null; // Cache expired
        }

        // Extract and return the data
        final data = wrapper['data'] as Map<String, dynamic>;
        return ProductResponse.fromJson(data);
      }
    } catch (e) {
      // Invalid cache data, ignore
    }
    return null;
  }

  /// Cache combo products data
  /// Only overwrites existing cache if data is successfully encoded
  Future<void> _cacheComboProducts(ProductResponse productResponse, int storeId) async {
    try {
      final jsonData = {
        'result_code': productResponse.resultCode,
        'products': productResponse.products.map((product) => _productToJson(product)).toList(),
        'desc': productResponse.desc,
      };

      // Wrap data with timestamp
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': jsonData,
      };

      // Try to encode JSON - will throw if invalid
      final encodedJson = json.encode(wrapper);

      // Only save if encoding succeeded
      final cacheKey = _getStoreSpecificKey(StorageKeys.comboProducts, storeId);
      await sharedPreferences.setString(cacheKey, encodedJson);
    } catch (e) {
      // Cache save failed (invalid JSON or encoding error)
      // Don't overwrite existing cache
    }
  }

  /// Clear menu cache for a specific store
  Future<void> clearMenuCache(int storeId) async {
    await sharedPreferences.remove(_getStoreSpecificKey(StorageKeys.menu, storeId));
    await sharedPreferences.remove(_getStoreSpecificKey(StorageKeys.productByStore, storeId));
    await sharedPreferences.remove(_getStoreSpecificKey(StorageKeys.productAtt, storeId));
    await sharedPreferences.remove(_getStoreSpecificKey(StorageKeys.comboActivities, storeId));
    await sharedPreferences.remove(_getStoreSpecificKey(StorageKeys.comboProducts, storeId));
  }

  /// Clear all menu caches for all stores
  Future<void> clearAllMenuCaches() async {
    final allKeys = sharedPreferences.getKeys();
    final menuKeys = allKeys.where((key) =>
      key.startsWith(StorageKeys.menu) ||
      key.startsWith(StorageKeys.productByStore) ||
      key.startsWith(StorageKeys.productAtt) ||
      key.startsWith(StorageKeys.comboActivities) ||
      key.startsWith(StorageKeys.comboProducts)
    );
    for (final key in menuKeys) {
      await sharedPreferences.remove(key);
    }
  }
}
