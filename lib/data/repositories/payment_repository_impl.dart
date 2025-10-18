import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/md5_helper.dart';
import '../models/cart_item_model.dart';
import '../models/sales_type_model.dart';
import '../models/store_credentials_model.dart';

/// Repository for handling payment and order submission
class PaymentRepository {
  final Dio _dio;

  PaymentRepository({Dio? dio}) : _dio = dio ?? Dio();

  /// Submit order to backend
  Future<Map<String, dynamic>> submitOrder({
    required List<CartItem> cartItems,
    required SalesTypeSelection salesTypeSelection,
    required int paymentMethodId,
    String? tableSessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt(StorageKeys.storeId) ?? 0;

    // Get credentials
    final credentials = await _getCredentials();

    // Build order object
    final orderRequest = _buildOrderRequest(
      cartItems: cartItems,
      storeId: storeId,
      salesTypeSelection: salesTypeSelection,
      paymentMethodId: paymentMethodId,
      tableSessionId: tableSessionId,
    );

    // Make API call
    final response = await _postWithAuth(
      endpoint: ApiConstants.sendMobileOrder,
      credentials: credentials,
      body: orderRequest,
    );

    return response;
  }

  /// Update payment status after payment gateway redirect
  Future<Map<String, dynamic>> updatePayment({
    required String cloudOrderNumber,
    required String resultIndicator,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt(StorageKeys.storeId) ?? 0;

    final credentials = await _getCredentials();

    final response = await _postWithAuth(
      endpoint: ApiConstants.paymentUpdate,
      credentials: credentials,
      body: {
        'cloudOrderNumber': cloudOrderNumber,
        'resultIndicator': resultIndicator,
        'storeId': storeId,
      },
    );

    return response;
  }

  /// Get stored credentials
  Future<StoreCredentialsModel> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getString(StorageKeys.storeCredentials);
    if (credentialsJson == null) {
      throw Exception('No stored credentials found');
    }

    final credentialsData = json.decode(credentialsJson) as Map<String, dynamic>;
    return StoreCredentialsModel.fromJson(credentialsData);
  }

  /// Make authenticated POST request
  Future<Map<String, dynamic>> _postWithAuth({
    required String endpoint,
    required StoreCredentialsModel credentials,
    required Map<String, dynamic> body,
  }) async {
    try {
      final bodyJson = json.encode(body);

      // Generate MD5 signature
      final timestamp = Md5Helper.getCurrentTimestamp();
      final signature = Md5Helper.generateSignature(
        appKey: credentials.appKey,
        appSecret: credentials.appSecret,
        uri: endpoint,
        body: bodyJson,
        timestamp: timestamp,
      );

      // Prepare headers
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

      // Make API call
      final url = '${credentials.apiDomain}/$endpoint';

      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Build order request object
  Map<String, dynamic> _buildOrderRequest({
    required List<CartItem> cartItems,
    required int storeId,
    required SalesTypeSelection salesTypeSelection,
    required int paymentMethodId,
    String? tableSessionId,
  }) {
    // Separate combo and single items
    final List<Map<String, dynamic>> singleItems = [];
    final List<Map<String, dynamic>> comboItems = [];

    double totalPrice = 0.0;

    for (final cartItem in cartItems) {
      final itemTotal = cartItem.totalPrice;
      totalPrice += itemTotal;

      if (cartItem.comboItems.isNotEmpty) {
        // Combo item
        comboItems.add(_buildComboItem(cartItem));
      } else {
        // Single item
        singleItems.add(_buildSingleItem(cartItem));
      }
    }

    // Get base URL for return URLs
    final baseUrl = Uri.base.origin;

    // Build payment object
    final payment = {
      'tender': totalPrice.toStringAsFixed(2),
      'methodnumber': paymentMethodId,
      if (paymentMethodId == 60 || paymentMethodId == 2013) 'status': 'pending',
    };

    // Get sales type number
    final salesTypeNum = _getSalesTypeNumber(
      salesTypeSelection.salesType,
      salesTypeSelection.schedule,
    );

    // Build transaction object
    final transaction = {
      'singleitems': {
        'singleitem': singleItems,
      },
      'comboitems': {
        'comboitem': comboItems,
      },
      'payments': {
        'payment': [payment],
      },
      'returnurl': '$baseUrl/processing',
      'cancelurl': '$baseUrl/payment-cancel',
      'timeouturl': '$baseUrl/payment-timeout',
      'saletypenum': salesTypeNum,
      'storeid': storeId,
      if (salesTypeSelection.pagerNumber != null && salesTypeSelection.pagerNumber!.isNotEmpty)
        'label': salesTypeSelection.pagerNumber,
      if (tableSessionId != null) 'tablesessionid': tableSessionId,
    };

    return {
      'request': {
        'transaction': transaction,
      },
    };
  }

  /// Build single item object
  Map<String, dynamic> _buildSingleItem(CartItem cartItem) {
    final item = {
      'mainproduct': cartItem.product.productSn,
      'quantity': cartItem.quantity,
      'costEach': cartItem.product.price,
    };

    // Add modifiers if any
    if (cartItem.modifiers.isNotEmpty) {
      final subproducts = cartItem.modifiers.map((modifier) {
        return {
          'subproduct': modifier.attValSn,
          'quantity': 1,
          'price': modifier.price.toStringAsFixed(2),
        };
      }).toList();

      item['subproducts'] = {
        'subproduct': subproducts,
      };
    } else {
      item['subproducts'] = {
        'subproduct': [],
      };
    }

    return item;
  }

  /// Build combo item object (simplified - combos not fully implemented yet)
  Map<String, dynamic> _buildComboItem(CartItem cartItem) {
    final List<Map<String, dynamic>> subproducts = [];

    // Add main combo item modifiers
    for (final modifier in cartItem.modifiers) {
      subproducts.add({
        'subproduct': modifier.attValSn,
        'quantity': 1,
        'price': modifier.price.toStringAsFixed(2),
      });
    }

    // Note: Combo products structure needs to be verified against API
    // This is a simplified implementation

    return {
      'mainproduct': cartItem.product.productSn,
      'quantity': cartItem.quantity,
      'costEach': cartItem.product.price,
      'subproducts': {
        'subproduct': subproducts,
      },
    };
  }

  /// Get sales type number from SalesType enum
  int _getSalesTypeNumber(SalesType salesType, OrderSchedule? schedule) {
    switch (salesType) {
      case SalesType.dineIn:
        return 3; // Dine-in
      case SalesType.pickup:
        // Check if ASAP or scheduled
        if (schedule != null && schedule.isASAP) {
          return 2; // Pickup ASAP
        } else {
          return 5; // Pickup scheduled
        }
    }
  }
}
