import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/md5_helper.dart';
import '../models/cart_item_model.dart';
import '../models/sales_type_model.dart';
import '../models/store_credentials_model.dart';
import '../models/store_info_model.dart';

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
    final orderRequest = await _buildOrderRequest(
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

  /// Get stored store info
  Future<StoreInfo> _getStoreInfo() async {
    print('[PaymentRepository] Getting store info...');
    final prefs = await SharedPreferences.getInstance();
    final storeInfoJson = prefs.getString(StorageKeys.storeInfo);
    if (storeInfoJson == null) {
      print('[PaymentRepository] ERROR: No stored store info found');
      throw Exception('No stored store info found');
    }

    print('[PaymentRepository] Decoding store info JSON...');
    final storeInfoData = json.decode(storeInfoJson) as Map<String, dynamic>;
    print('[PaymentRepository] Creating StoreInfo from JSON...');

    try {
      final storeInfo = StoreInfo.fromJson(storeInfoData);
      print('[PaymentRepository] StoreInfo created successfully');
      return storeInfo;
    } catch (e, stackTrace) {
      print('[PaymentRepository] ERROR creating StoreInfo: $e');
      print('[PaymentRepository] Stack trace: $stackTrace');
      rethrow;
    }
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
  Future<Map<String, dynamic>> _buildOrderRequest({
    required List<CartItem> cartItems,
    required int storeId,
    required SalesTypeSelection salesTypeSelection,
    required int paymentMethodId,
    String? tableSessionId,
  }) async {
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

    // Get store info to retrieve sales type configuration
    final storeInfo = await _getStoreInfo();
    final salesTypeConfig = storeInfo.salesTypeConfig;

    // Get sales type number from configuration
    final salesTypeNum = _getSalesTypeNumber(
      salesTypeSelection.salesType,
      salesTypeSelection.schedule,
      salesTypeConfig,
    );

    print('[PaymentRepository] Sales type number: $salesTypeNum');

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
      'prodNum': cartItem.product.productSn,  // Capital N - STRING per C# model
      'quantity': cartItem.quantity,
      'modifiers': [],  // lowercase
    };

    // Add modifiers if any
    if (cartItem.modifiers.isNotEmpty) {
      item['modifiers'] = cartItem.modifiers.map((modifier) {
        return {
          'prodNum': modifier.attValSn,  // Capital N - STRING per C# model
          'quantity': 1,
          'description': modifier.attValName,
        };
      }).toList();
    }

    return item;
  }

  /// Build combo item object
  Map<String, dynamic> _buildComboItem(CartItem cartItem) {
    print('[PaymentRepository] Building combo item...');
    print('[PaymentRepository] Main product: ${cartItem.product.productSn}');
    print('[PaymentRepository] Main modifiers count: ${cartItem.modifiers.length}');
    print('[PaymentRepository] Combo items count: ${cartItem.comboItems.length}');

    final List<Map<String, dynamic>> subproducts = [];

    // Add combo sub-products
    for (final comboItem in cartItem.comboItems) {
      print('[PaymentRepository] Combo sub-product SN: ${comboItem.productSn}');
      print('[PaymentRepository] Combo sub-product modifiers: ${comboItem.modifiers.length}');

      // Build modifiers array for this sub-product
      final modifiers = comboItem.modifiers.map((modifier) {
        return {
          'prodNum': modifier.attValSn,  // Capital N - STRING per C# model
          'quantity': 1,
          'description': modifier.attValName,
        };
      }).toList();

      subproducts.add({
        'prodNum': comboItem.productSn,  // Capital N - STRING per C# model (use productSn not productId)
        'quantity': 1,
        'modifiers': modifiers,
      });
    }

    print('[PaymentRepository] Total subproducts built: ${subproducts.length}');

    // Build main product modifiers
    final mainModifiers = cartItem.modifiers.map((modifier) {
      return {
        'prodNum': modifier.attValSn,  // Capital N - STRING per C# model
        'quantity': 1,
        'description': modifier.attValName,
      };
    }).toList();

    print('[PaymentRepository] Main product modifiers built: ${mainModifiers.length}');

    return {
      'mainProduct': cartItem.product.productSn,  // Capital P - STRING per C# model
      'quantity': cartItem.quantity,
      'modifiers': mainModifiers,  // Add main product modifiers
      'subProducts': {  // Capital P
        'subProduct': subproducts,  // Capital P
      },
    };
  }

  /// Get sales type number from SalesType enum using store configuration
  int _getSalesTypeNumber(
    SalesType salesType,
    OrderSchedule? schedule,
    SalesTypeConfig config,
  ) {
    print('[PaymentRepository] Getting sales type number...');
    print('[PaymentRepository] salesType: $salesType');
    print('[PaymentRepository] schedule: ${schedule?.isASAP}');
    print('[PaymentRepository] config.dineIn?.id: ${config.dineIn?.id}');
    print('[PaymentRepository] config.takeaway?.id: ${config.takeaway?.id}');
    print('[PaymentRepository] config.pickUp?.id: ${config.pickUp?.id}');

    int result;
    switch (salesType) {
      case SalesType.dineIn:
        result = config.dineIn?.id ?? 1; // Dine-in (default: 1)
        print('[PaymentRepository] Using dineIn: $result');
        break;
      case SalesType.pickup:
        // Check if ASAP or scheduled
        if (schedule != null && schedule.isASAP) {
          result = config.takeaway?.id ?? 2; // Pickup ASAP / Takeaway (default: 2)
          print('[PaymentRepository] Using takeaway (ASAP): $result');
        } else {
          result = config.pickUp?.id ?? 5; // Pickup scheduled (default: 5)
          print('[PaymentRepository] Using pickUp (scheduled): $result');
        }
        break;
    }

    print('[PaymentRepository] Final sales type number: $result');
    print('[PaymentRepository] Sales type number type: ${result.runtimeType}');

    return result;
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
