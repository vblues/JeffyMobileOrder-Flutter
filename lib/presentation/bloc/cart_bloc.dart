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
    on<UpdateCartItem>(_onUpdateCartItem);
    on<ClearCart>(_onClearCart);
    on<RefreshCart>(_onRefreshCart);
    on<AddCartItems>(_onAddCartItems);
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

      // Check if an identical item already exists in cart
      final matchingItem = findMatchingCartItem(
        event.product.productId,
        cartModifiers,
        cartComboItems,
      );

      final List<CartItem> updatedItems;
      final CartItem resultItem;

      if (matchingItem != null) {
        // Increment quantity of existing item
        final incrementedItem = matchingItem.copyWith(
          quantity: matchingItem.quantity + event.quantity,
        );

        updatedItems = state.items.map((item) {
          if (item.id == matchingItem.id) {
            return incrementedItem;
          }
          return item;
        }).toList();

        resultItem = incrementedItem;
      } else {
        // Create new cart item
        resultItem = CartItem(
          id: _uuid.v4(),
          product: event.product,
          quantity: event.quantity,
          modifiers: cartModifiers,
          comboItems: cartComboItems,
        );

        updatedItems = List<CartItem>.from(state.items)..add(resultItem);
      }

      final summary = _calculateSummary(updatedItems);

      // Save to storage
      await _repository.saveCart(updatedItems);

      emit(CartItemAdded(
        addedItem: resultItem,
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

  /// Update cart item's modifiers and combos
  Future<void> _onUpdateCartItem(
      UpdateCartItem event, Emitter<CartState> emit) async {
    try {
      // Find the cart item to update
      final itemToUpdate = state.items.firstWhere(
        (item) => item.id == event.cartItemId,
        orElse: () => throw Exception('Cart item not found'),
      );

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

      // Update the item with new modifiers and combos (keeping same quantity)
      final updatedItem = itemToUpdate.copyWith(
        modifiers: cartModifiers,
        comboItems: cartComboItems,
      );

      // Replace the item in the list
      final updatedItems = state.items.map((item) {
        if (item.id == event.cartItemId) {
          return updatedItem;
        }
        return item;
      }).toList();

      final summary = _calculateSummary(updatedItems);

      // Save to storage
      await _repository.saveCart(updatedItems);

      emit(CartItemUpdated(
        updatedItemId: event.cartItemId,
        newQuantity: updatedItem.quantity,
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

  /// Add multiple cart items directly (for reordering from history)
  Future<void> _onAddCartItems(
      AddCartItems event, Emitter<CartState> emit) async {
    try {
      // Generate new IDs for all items to avoid conflicts
      final itemsWithNewIds = event.items.map((item) {
        return item.copyWith(
          id: _uuid.v4(),
          addedAt: DateTime.now(),
        );
      }).toList();

      // Add to existing cart
      final updatedItems = List<CartItem>.from(state.items)
        ..addAll(itemsWithNewIds);

      final summary = _calculateSummary(updatedItems);

      // Save to storage
      await _repository.saveCart(updatedItems);

      emit(CartLoaded(items: updatedItems, summary: summary));
    } catch (e) {
      emit(CartError(
        message: 'Failed to add cart items: $e',
        items: state.items,
        summary: state.summary,
      ));
    }
  }

  /// Find existing cart item that matches the product and customizations
  /// Returns the matching CartItem if found, null otherwise
  CartItem? findMatchingCartItem(
    int productId,
    List<CartModifier> modifiers,
    List<CartComboItem> comboItems,
  ) {
    for (final item in state.items) {
      // Check if product ID matches
      if (item.product.productId != productId) continue;

      // Check if modifiers match (same count and same values)
      if (!_modifiersMatch(item.modifiers, modifiers)) continue;

      // Check if combo items match (same count and same values)
      if (!_comboItemsMatch(item.comboItems, comboItems)) continue;

      // Found a match!
      return item;
    }
    return null;
  }

  /// Check if two lists of modifiers are identical
  bool _modifiersMatch(List<CartModifier> a, List<CartModifier> b) {
    if (a.length != b.length) return false;

    // Create sorted lists of modifier identifiers for comparison
    final aIds = a.map((m) => '${m.attId}_${m.attValId}').toList()..sort();
    final bIds = b.map((m) => '${m.attId}_${m.attValId}').toList()..sort();

    for (int i = 0; i < aIds.length; i++) {
      if (aIds[i] != bIds[i]) return false;
    }
    return true;
  }

  /// Check if two lists of combo items are identical
  bool _comboItemsMatch(List<CartComboItem> a, List<CartComboItem> b) {
    if (a.length != b.length) return false;

    // Create sorted lists for comparison
    final aSorted = List<CartComboItem>.from(a)
      ..sort((x, y) => '${x.categoryTypeNameSn}_${x.productId}'
          .compareTo('${y.categoryTypeNameSn}_${y.productId}'));
    final bSorted = List<CartComboItem>.from(b)
      ..sort((x, y) => '${x.categoryTypeNameSn}_${x.productId}'
          .compareTo('${y.categoryTypeNameSn}_${y.productId}'));

    for (int i = 0; i < aSorted.length; i++) {
      final aItem = aSorted[i];
      final bItem = bSorted[i];

      // Check category and product match
      if (aItem.categoryTypeNameSn != bItem.categoryTypeNameSn ||
          aItem.productId != bItem.productId) {
        return false;
      }

      // Check modifiers for this combo item match
      if (!_modifiersMatch(aItem.modifiers, bItem.modifiers)) {
        return false;
      }
    }
    return true;
  }

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
