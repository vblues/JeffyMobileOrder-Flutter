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
    final storeId = _getStoreId(prefs);

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
    final storeId = _getStoreId(prefs);

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

      print('[PaymentRepository] Sending request to: $url');
      print('[PaymentRepository] Headers: $headers');
      print('[PaymentRepository] Body: $bodyJson');

      final response = await _dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      print('[PaymentRepository] Response status: ${response.statusCode}');
      print('[PaymentRepository] Response data: ${response.data}');

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
    print('[PaymentRepository] Building order request...');
    print('[PaymentRepository] Cart items count: ${cartItems.length}');
    print('[PaymentRepository] Store ID: $storeId');
    print('[PaymentRepository] Payment method ID: $paymentMethodId');

    // Separate combo and single items
    final List<Map<String, dynamic>> singleItems = [];
    final List<Map<String, dynamic>> comboItems = [];

    double totalPrice = 0.0;

    for (final cartItem in cartItems) {
      print('[PaymentRepository] Processing cart item: ${cartItem.product.productName}');
      final itemTotal = cartItem.totalPrice;
      totalPrice += itemTotal;

      if (cartItem.comboItems.isNotEmpty) {
        // Combo item
        print('[PaymentRepository] Item is combo');
        comboItems.add(_buildComboItem(cartItem));
      } else {
        // Single item
        print('[PaymentRepository] Item is single');
        singleItems.add(_buildSingleItem(cartItem));
      }
    }

    print('[PaymentRepository] Single items count: ${singleItems.length}');
    print('[PaymentRepository] Combo items count: ${comboItems.length}');
    print('[PaymentRepository] Total price: \$${totalPrice.toStringAsFixed(2)}');

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

    final orderRequest = {
      'request': {
        'transaction': transaction,
      },
    };

    print('[PaymentRepository] Final order request: ${json.encode(orderRequest)}');

    return orderRequest;
  }

  /// Build single item object
  Map<String, dynamic> _buildSingleItem(CartItem cartItem) {
    final item = {
      'prodNum': cartItem.product.productSn,  // Changed from 'mainproduct' to 'prodNum'
      'quantity': cartItem.quantity,
      'costEach': cartItem.product.price,
      'Modifiers': [],  // Changed from 'subproducts' to 'Modifiers' array
    };

    // Add modifiers if any
    if (cartItem.modifiers.isNotEmpty) {
      item['Modifiers'] = cartItem.modifiers.map((modifier) {
        return {
          'subproduct': modifier.attValSn,
          'quantity': 1,
          'price': modifier.price.toStringAsFixed(2),
        };
      }).toList();
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

  /// Helper to get store ID handling both int and string storage
  int _getStoreId(SharedPreferences prefs) {
    // Try to get as int first
    try {
      final intValue = prefs.getInt(StorageKeys.storeId);
      if (intValue != null) {
        return intValue;
      }
    } catch (e) {
      // getInt() throws if stored as string
    }

    // Fallback: try to get as string and parse
    try {
      final stringValue = prefs.getString(StorageKeys.storeId);
      if (stringValue != null) {
        return int.parse(stringValue);
      }
    } catch (e) {
      // Failed to parse string
    }

    return 0; // Default fallback
  }
}
