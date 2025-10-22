import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_attribute_model.dart';
import '../../data/models/combo_model.dart';

/// Base class for all cart events
abstract class CartEvent {}

/// Load cart from storage
class LoadCart extends CartEvent {}

/// Add item to cart
class AddToCart extends CartEvent {
  final Product product;
  final int quantity;
  final Map<int, List<AttributeValue>> selectedModifiers;
  final Map<String, List<SelectedComboItem>> selectedCombos;

  AddToCart({
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const {},
    this.selectedCombos = const {},
  });
}

/// Remove item from cart
class RemoveFromCart extends CartEvent {
  final String cartItemId;

  RemoveFromCart(this.cartItemId);
}

/// Update item quantity
class UpdateCartItemQuantity extends CartEvent {
  final String cartItemId;
  final int newQuantity;

  UpdateCartItemQuantity({
    required this.cartItemId,
    required this.newQuantity,
  });
}

/// Clear entire cart
class ClearCart extends CartEvent {}

/// Refresh cart (recalculate totals)
class RefreshCart extends CartEvent {}

/// Validate cart belongs to current store and clear if not
class ValidateCartStore extends CartEvent {}

/// Add multiple cart items directly (for reordering from history)
class AddCartItems extends CartEvent {
  final List<CartItem> items;

  AddCartItems(this.items);
}
