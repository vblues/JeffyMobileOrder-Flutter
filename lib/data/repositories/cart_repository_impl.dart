import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../../core/constants/storage_keys.dart';

/// Repository for cart data persistence
class CartRepository {
  final SharedPreferences _prefs;

  CartRepository(this._prefs);

  /// Save cart items to storage
  Future<void> saveCart(List<CartItem> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(StorageKeys.cart, jsonString);
    } catch (e) {
      throw Exception('Failed to save cart: $e');
    }
  }

  /// Load cart items from storage
  Future<List<CartItem>> loadCart() async {
    try {
      final jsonString = _prefs.getString(StorageKeys.cart);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If cart is corrupted, return empty and clear storage
      await clearCart();
      return [];
    }
  }

  /// Clear cart from storage
  Future<void> clearCart() async {
    try {
      await _prefs.remove(StorageKeys.cart);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// Check if cart exists in storage
  bool hasCart() {
    return _prefs.containsKey(StorageKeys.cart);
  }

  /// Get cart item count from storage (without loading full cart)
  Future<int> getCartItemCount() async {
    try {
      final items = await loadCart();
      int count = 0;
      for (final item in items) {
        count += item.quantity;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }
}
