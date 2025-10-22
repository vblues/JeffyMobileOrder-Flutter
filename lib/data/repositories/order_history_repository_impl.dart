import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_history_model.dart';
import '../../core/constants/storage_keys.dart';

/// Repository for order history persistence
class OrderHistoryRepository {
  final SharedPreferences _prefs;
  static const int maxOrderHistoryCount = 100;

  OrderHistoryRepository(this._prefs);

  /// Save a new order to history
  /// Automatically maintains max 100 orders by removing oldest
  Future<void> saveOrder(OrderHistoryItem order) async {
    try {
      // Load existing history
      final history = await loadOrderHistory();

      // Add new order at the beginning (newest first)
      history.insert(0, order);

      // Remove oldest orders if exceeding limit
      if (history.length > maxOrderHistoryCount) {
        history.removeRange(maxOrderHistoryCount, history.length);
      }

      // Save updated history
      await _saveOrderList(history);
    } catch (e) {
      throw Exception('Failed to save order: $e');
    }
  }

  /// Load all order history from storage (newest first)
  Future<List<OrderHistoryItem>> loadOrderHistory() async {
    try {
      final jsonString = _prefs.getString(StorageKeys.orderHistory);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => OrderHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If history is corrupted, return empty and clear storage
      await clearHistory();
      return [];
    }
  }

  /// Delete a specific order from history
  Future<void> deleteOrder(String orderId) async {
    try {
      final history = await loadOrderHistory();
      history.removeWhere((order) => order.id == orderId);
      await _saveOrderList(history);
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  /// Clear all order history
  Future<void> clearHistory() async {
    try {
      await _prefs.remove(StorageKeys.orderHistory);
    } catch (e) {
      throw Exception('Failed to clear order history: $e');
    }
  }

  /// Check if order history exists
  bool hasHistory() {
    return _prefs.containsKey(StorageKeys.orderHistory);
  }

  /// Get order history count
  Future<int> getOrderCount() async {
    try {
      final history = await loadOrderHistory();
      return history.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get order by ID
  Future<OrderHistoryItem?> getOrderById(String orderId) async {
    try {
      final history = await loadOrderHistory();
      return history.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Private helper to save order list to storage
  Future<void> _saveOrderList(List<OrderHistoryItem> orders) async {
    try {
      final jsonList = orders.map((order) => order.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(StorageKeys.orderHistory, jsonString);
    } catch (e) {
      throw Exception('Failed to save order list: $e');
    }
  }
}
