import '../../data/models/order_history_model.dart';

/// Base class for all order history events
abstract class OrderHistoryEvent {}

/// Load order history from storage
class LoadOrderHistory extends OrderHistoryEvent {}

/// Reorder items from a past order
class ReorderFromHistory extends OrderHistoryEvent {
  final OrderHistoryItem order;

  ReorderFromHistory(this.order);
}

/// Delete a specific order from history
class DeleteOrder extends OrderHistoryEvent {
  final String orderId;

  DeleteOrder(this.orderId);
}

/// Clear all order history
class ClearAllOrders extends OrderHistoryEvent {}
