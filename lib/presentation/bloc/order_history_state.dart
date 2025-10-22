import '../../data/models/order_history_model.dart';

/// Base class for all order history states
abstract class OrderHistoryState {
  final List<OrderHistoryItem> orders;

  OrderHistoryState({required this.orders});

  /// Check if history is empty
  bool get isEmpty => orders.isEmpty;

  /// Get order count
  int get orderCount => orders.length;
}

/// Initial state
class OrderHistoryInitial extends OrderHistoryState {
  OrderHistoryInitial() : super(orders: []);
}

/// Loading order history from storage
class OrderHistoryLoading extends OrderHistoryState {
  OrderHistoryLoading({required List<OrderHistoryItem> orders})
      : super(orders: orders);
}

/// Order history loaded successfully
class OrderHistoryLoaded extends OrderHistoryState {
  OrderHistoryLoaded({required List<OrderHistoryItem> orders})
      : super(orders: orders);
}

/// Order deleted successfully
class OrderDeleted extends OrderHistoryState {
  final String deletedOrderId;

  OrderDeleted({
    required this.deletedOrderId,
    required List<OrderHistoryItem> orders,
  }) : super(orders: orders);
}

/// All orders cleared
class OrderHistoryCleared extends OrderHistoryState {
  OrderHistoryCleared() : super(orders: []);
}

/// Order reordered successfully (items added back to cart)
class OrderReordered extends OrderHistoryState {
  final OrderHistoryItem reorderedOrder;

  OrderReordered({
    required this.reorderedOrder,
    required List<OrderHistoryItem> orders,
  }) : super(orders: orders);
}

/// Error state
class OrderHistoryError extends OrderHistoryState {
  final String message;

  OrderHistoryError({
    required this.message,
    required List<OrderHistoryItem> orders,
  }) : super(orders: orders);
}
