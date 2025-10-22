import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/md5_helper.dart';
import '../models/menu_model.dart';
import '../models/product_model.dart';
import '../models/product_attribute_model.dart';
import '../models/combo_model.dart';
import '../models/store_credentials_model.dart';

class MenuRemoteDataSource {
  final Dio _dio;

  MenuRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch menu categories from API
  ///
  /// Requires store credentials for MD5 authentication
  /// Returns MenuResponse with hierarchical category structure
  Future<MenuResponse> getMenu({
    required StoreCredentialsModel credentials,
    required int storeId,
  }) async {
    final requestBody = {
      'store_id': storeId,
      'redeemable': 0,
    };

    final bodyJson = json.encode(requestBody);
    final timestamp = Md5Helper.getCurrentTimestamp();
    final signature = Md5Helper.generateSignature(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      uri: ApiConstants.getMenu,
      body: bodyJson,
      timestamp: timestamp,
    );

    final headers = {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerTenantId: credentials.tenantId,
      ApiConstants.headerTime: timestamp.toString(),
      ApiConstants.headerSign: signature,
      ApiConstants.headerAppKey: credentials.appKey,
      ApiConstants.headerSerialNumber: credentials.deviceId,
      ApiConstants.headerSaleChannel: ApiConstants.saleChannelApp,
      ApiConstants.headerUpdateChannel: ApiConstants.updateChannelApp,
    };

    final url = '${credentials.apiDomain}/${ApiConstants.getMenu}';

    try {
      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      return MenuResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Fetch products by store from API
  ///
  /// Requires store credentials for MD5 authentication
  /// Returns ProductResponse with list of all products
  Future<ProductResponse> getProductByStore({
    required StoreCredentialsModel credentials,
    required int storeId,
  }) async {
    final requestBody = {
      'store_id': storeId,
    };

    final bodyJson = json.encode(requestBody);
    final timestamp = Md5Helper.getCurrentTimestamp();
    final signature = Md5Helper.generateSignature(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      uri: ApiConstants.getProductByStore,
      body: bodyJson,
      timestamp: timestamp,
    );

    final headers = {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerTenantId: credentials.tenantId,
      ApiConstants.headerTime: timestamp.toString(),
      ApiConstants.headerSign: signature,
      ApiConstants.headerAppKey: credentials.appKey,
      ApiConstants.headerSerialNumber: credentials.deviceId,
      ApiConstants.headerSaleChannel: ApiConstants.saleChannelApp,
      ApiConstants.headerUpdateChannel: ApiConstants.updateChannelApp,
    };

    final url = '${credentials.apiDomain}/${ApiConstants.getProductByStore}';

    try {
      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      return ProductResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Fetch product attributes (modifiers) from API
  ///
  /// Requires store credentials for MD5 authentication
  /// Returns ProductAttributeResponse with all product modifiers
  Future<ProductAttributeResponse> getProductAtt({
    required StoreCredentialsModel credentials,
    required int storeId,
  }) async {
    final requestBody = {
      'store_id': storeId,
    };

    final bodyJson = json.encode(requestBody);
    final timestamp = Md5Helper.getCurrentTimestamp();
    final signature = Md5Helper.generateSignature(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      uri: ApiConstants.getProductAtt,
      body: bodyJson,
      timestamp: timestamp,
    );

    final headers = {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerTenantId: credentials.tenantId,
      ApiConstants.headerTime: timestamp.toString(),
      ApiConstants.headerSign: signature,
      ApiConstants.headerAppKey: credentials.appKey,
      ApiConstants.headerSerialNumber: credentials.deviceId,
      ApiConstants.headerSaleChannel: ApiConstants.saleChannelApp,
      ApiConstants.headerUpdateChannel: ApiConstants.updateChannelApp,
    };

    final url = '${credentials.apiDomain}/${ApiConstants.getProductAtt}';

    try {
      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      return ProductAttributeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Fetch combo/activity configurations with pricing from API
  ///
  /// Requires store credentials for MD5 authentication
  /// Returns ComboActivityResponse with all active combos
  Future<ComboActivityResponse> getActivityComboWithPrice({
    required StoreCredentialsModel credentials,
    required int storeId,
  }) async {
    final requestBody = {
      'store_id': storeId,
    };

    final bodyJson = json.encode(requestBody);
    final timestamp = Md5Helper.getCurrentTimestamp();
    final signature = Md5Helper.generateSignature(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      uri: ApiConstants.getActivityComboWithPrice,
      body: bodyJson,
      timestamp: timestamp,
    );

    final headers = {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerTenantId: credentials.tenantId,
      ApiConstants.headerTime: timestamp.toString(),
      ApiConstants.headerSign: signature,
      ApiConstants.headerAppKey: credentials.appKey,
      ApiConstants.headerSerialNumber: credentials.deviceId,
      ApiConstants.headerSaleChannel: ApiConstants.saleChannelApp,
      ApiConstants.headerUpdateChannel: ApiConstants.updateChannelApp,
    };

    final url = '${credentials.apiDomain}/${ApiConstants.getActivityComboWithPrice}';

    try {
      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      return ComboActivityResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Fetch store combo products from API
  ///
  /// Requires store credentials for MD5 authentication
  /// Returns ProductResponse with products available in combos
  Future<ProductResponse> getStoreComboProduct({
    required StoreCredentialsModel credentials,
    required int storeId,
  }) async {
    final requestBody = {
      'store_id': storeId,
    };

    final bodyJson = json.encode(requestBody);
    final timestamp = Md5Helper.getCurrentTimestamp();
    final signature = Md5Helper.generateSignature(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      uri: ApiConstants.getStoreComboProduct,
      body: bodyJson,
      timestamp: timestamp,
    );

    final headers = {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerTenantId: credentials.tenantId,
      ApiConstants.headerTime: timestamp.toString(),
      ApiConstants.headerSign: signature,
      ApiConstants.headerAppKey: credentials.appKey,
      ApiConstants.headerSerialNumber: credentials.deviceId,
      ApiConstants.headerSaleChannel: ApiConstants.saleChannelApp,
      ApiConstants.headerUpdateChannel: ApiConstants.updateChannelApp,
    };

    final url = '${credentials.apiDomain}/${ApiConstants.getStoreComboProduct}';

    try {
      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      return ProductResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['desc'] ?? 'Server error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      default:
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }
}
