import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../../core/constants/storage_keys.dart';

/// Repository for cart data persistence
class CartRepository {
  final SharedPreferences _prefs;

  CartRepository(this._prefs);

  /// Save cart items to storage along with the store ID
  Future<void> saveCart(List<CartItem> items, {int? storeId}) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(StorageKeys.cart, jsonString);

      // Save the store ID that this cart belongs to
      if (storeId != null) {
        await _prefs.setInt(StorageKeys.cartStoreId, storeId);
      }
    } catch (e, stackTrace) {
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
      await _prefs.remove(StorageKeys.cartStoreId);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// Get the store ID that the current cart belongs to
  int? getCartStoreId() {
    // Try to get as int first
    try {
      final intValue = _prefs.getInt(StorageKeys.cartStoreId);
      if (intValue != null) {
        return intValue;
      }
    } catch (e) {
      // getInt() throws if stored as string, fall through to string parsing
    }

    // Fallback: try to get as string and parse
    try {
      final stringValue = _prefs.getString(StorageKeys.cartStoreId);
      if (stringValue != null) {
        final parsed = int.parse(stringValue);
        // Save it back as an int for next time
        _prefs.setInt(StorageKeys.cartStoreId, parsed);
        return parsed;
      }
    } catch (e) {
      // Failed to parse string
    }

    return null;
  }

  /// Get the currently selected store ID
  int? getCurrentStoreId() {
    // Try to get as int first
    try {
      final intValue = _prefs.getInt(StorageKeys.storeId);
      if (intValue != null) {
        return intValue;
      }
    } catch (e) {
      // getInt() throws if stored as string, fall through to string parsing
    }

    // Fallback: try to get as string and parse
    try {
      final stringValue = _prefs.getString(StorageKeys.storeId);
      if (stringValue != null) {
        final parsed = int.parse(stringValue);
        // Save it back as an int for next time
        _prefs.setInt(StorageKeys.storeId, parsed);
        return parsed;
      }
    } catch (e) {
      // Failed to parse string
    }

    return null;
  }

  /// Check if cart belongs to the current store
  /// Returns true if cart is valid for current store, false if it should be cleared
  bool isCartValidForCurrentStore() {
    final cartStoreId = getCartStoreId();
    final currentStoreId = getCurrentStoreId();

    // If there's no cart or no store selected, consider it valid
    if (cartStoreId == null || currentStoreId == null) {
      return true;
    }

    // Cart is only valid if it belongs to the current store
    return cartStoreId == currentStoreId;
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
