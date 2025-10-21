import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/repositories/cart_repository_impl.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// BLoC for cart management
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _repository;
  final _uuid = const Uuid();

  CartBloc(this._repository) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<ClearCart>(_onClearCart);
    on<RefreshCart>(_onRefreshCart);
  }

  /// Load cart from storage
  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    try {
      emit(CartLoading(
        items: state.items,
        summary: state.summary,
      ));

      final items = await _repository.loadCart();
      final summary = _calculateSummary(items);

      emit(CartLoaded(items: items, summary: summary));
    } catch (e) {
      emit(CartError(
        message: 'Failed to load cart: $e',
        items: state.items,
        summary: state.summary,
      ));
    }
  }

  /// Add item to cart
  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      // Create cart modifiers from selected modifiers
      final List<CartModifier> cartModifiers = [];
      event.selectedModifiers.forEach((attId, values) {
        for (final value in values) {
          final modifier = CartModifier.fromAttributeValue(
            attId,
            'Modifier $attId', // Attribute name - will be overridden by UI context
            value,
          );
          cartModifiers.add(modifier);
        }
      });

      // Create cart combo items from selected combos
      final List<CartComboItem> cartComboItems = [];
      event.selectedCombos.forEach((category, items) {
        for (final item in items) {
          final comboItem = CartComboItem.fromSelectedComboItem(item);
          cartComboItems.add(comboItem);
        }
      });

      // Create new cart item
      final cartItem = CartItem(
        id: _uuid.v4(),
        product: event.product,
        quantity: event.quantity,
        modifiers: cartModifiers,
        comboItems: cartComboItems,
      );

      // Add to cart
      final updatedItems = List<CartItem>.from(state.items)..add(cartItem);

      final summary = _calculateSummary(updatedItems);

      // Save to storage
      await _repository.saveCart(updatedItems);

      emit(CartItemAdded(
        addedItem: cartItem,
        items: updatedItems,
        summary: summary,
      ));
    } catch (e, stackTrace) {
      emit(CartError(
        message: 'Failed to add item to cart: $e',
        items: state.items,
        summary: state.summary,
      ));
    }
  }

  /// Remove item from cart
  Future<void> _onRemoveFromCart(
      RemoveFromCart event, Emitter<CartState> emit) async {
    try {
      final updatedItems = state.items
          .where((item) => item.id != event.cartItemId)
          .toList();
      final summary = _calculateSummary(updatedItems);

      // Save to storage
      await _repository.saveCart(updatedItems);

      emit(CartItemRemoved(
        removedItemId: event.cartItemId,
        items: updatedItems,
        summary: summary,
      ));
    } catch (e) {
      emit(CartError(
        message: 'Failed to remove item from cart: $e',
        items: state.items,
        summary: state.summary,
      ));
    }
  }

  /// Update cart item quantity
  Future<void> _onUpdateCartItemQuantity(
      UpdateCartItemQuantity event, Emitter<CartState> emit) async {
    try {
      // Find and update the item
      final updatedItems = state.items.map((item) {
        if (item.id == event.cartItemId) {
          return item.copyWith(quantity: event.newQuantity);
        }
        return item;
      }).toList();

      // Remove items with quantity 0
      updatedItems.removeWhere((item) => item.quantity <= 0);

      final summary = _calculateSummary(updatedItems);

      // Save to storage
      await _repository.saveCart(updatedItems);

      emit(CartItemUpdated(
        updatedItemId: event.cartItemId,
        newQuantity: event.newQuantity,
        items: updatedItems,
        summary: summary,
      ));
    } catch (e) {
      emit(CartError(
        message: 'Failed to update cart item: $e',
        items: state.items,
        summary: state.summary,
      ));
    }
  }

  /// Clear cart
  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      await _repository.clearCart();
      emit(CartCleared());
    } catch (e) {
      emit(CartError(
        message: 'Failed to clear cart: $e',
        items: state.items,
        summary: state.summary,
      ));
    }
  }

  /// Refresh cart (recalculate totals)
  Future<void> _onRefreshCart(
      RefreshCart event, Emitter<CartState> emit) async {
    final summary = _calculateSummary(state.items);
    emit(CartLoaded(items: state.items, summary: summary));
  }

  /// Validate cart belongs to current store
  /// Calculate cart summary
  CartSummary _calculateSummary(List<CartItem> items) {
    if (items.isEmpty) {
      return CartSummary(
        itemCount: 0,
        totalQuantity: 0,
        subtotal: 0.0,
      );
    }

    final itemCount = items.length;
    final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);

    // TODO: Calculate service charge and tax based on store settings
    final serviceCharge = 0.0;
    final tax = 0.0;

    return CartSummary(
      itemCount: itemCount,
      totalQuantity: totalQuantity,
      subtotal: subtotal,
      serviceCharge: serviceCharge,
      tax: tax,
    );
  }
}
