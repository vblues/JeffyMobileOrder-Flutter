import '../../data/models/cart_item_model.dart';

/// Base class for all cart states
abstract class CartState {
  final List<CartItem> items;
  final CartSummary summary;

  CartState({
    required this.items,
    required this.summary,
  });

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Get total item count (sum of quantities)
  int get totalItemCount => summary.totalQuantity;

  /// Get unique product count
  int get uniqueProductCount => items.length;
}

/// Initial state
class CartInitial extends CartState {
  CartInitial()
      : super(
          items: [],
          summary: CartSummary(
            itemCount: 0,
            totalQuantity: 0,
            subtotal: 0.0,
          ),
        );
}

/// Loading cart from storage
class CartLoading extends CartState {
  CartLoading({
    required List<CartItem> items,
    required CartSummary summary,
  }) : super(items: items, summary: summary);
}

/// Cart loaded successfully
class CartLoaded extends CartState {
  CartLoaded({
    required List<CartItem> items,
    required CartSummary summary,
  }) : super(items: items, summary: summary);
}

/// Item added to cart
class CartItemAdded extends CartState {
  final CartItem addedItem;

  CartItemAdded({
    required this.addedItem,
    required List<CartItem> items,
    required CartSummary summary,
  }) : super(items: items, summary: summary);
}

/// Item removed from cart
class CartItemRemoved extends CartState {
  final String removedItemId;

  CartItemRemoved({
    required this.removedItemId,
    required List<CartItem> items,
    required CartSummary summary,
  }) : super(items: items, summary: summary);
}

/// Item quantity updated
class CartItemUpdated extends CartState {
  final String updatedItemId;
  final int newQuantity;

  CartItemUpdated({
    required this.updatedItemId,
    required this.newQuantity,
    required List<CartItem> items,
    required CartSummary summary,
  }) : super(items: items, summary: summary);
}

/// Cart cleared
class CartCleared extends CartState {
  CartCleared()
      : super(
          items: [],
          summary: CartSummary(
            itemCount: 0,
            totalQuantity: 0,
            subtotal: 0.0,
          ),
        );
}

/// Cart error state
class CartError extends CartState {
  final String message;

  CartError({
    required this.message,
    required List<CartItem> items,
    required CartSummary summary,
  }) : super(items: items, summary: summary);
}
