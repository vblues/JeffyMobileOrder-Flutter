import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/order_history_repository_impl.dart';
import 'order_history_event.dart';
import 'order_history_state.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

/// BLoC for order history management
class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderHistoryRepository _repository;
  final CartBloc _cartBloc;

  OrderHistoryBloc(this._repository, this._cartBloc)
      : super(OrderHistoryInitial()) {
    on<LoadOrderHistory>(_onLoadOrderHistory);
    on<ReorderFromHistory>(_onReorderFromHistory);
    on<DeleteOrder>(_onDeleteOrder);
    on<ClearAllOrders>(_onClearAllOrders);
  }

  /// Load order history from storage
  Future<void> _onLoadOrderHistory(
    LoadOrderHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    try {
      emit(OrderHistoryLoading(orders: state.orders));

      final orders = await _repository.loadOrderHistory();

      emit(OrderHistoryLoaded(orders: orders));
    } catch (e) {
      emit(OrderHistoryError(
        message: 'Failed to load order history: $e',
        orders: state.orders,
      ));
    }
  }

  /// Reorder items from a past order
  Future<void> _onReorderFromHistory(
    ReorderFromHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    try {
      // Add all items from the order to the cart (without clearing existing items)
      _cartBloc.add(AddCartItems(event.order.items));

      emit(OrderReordered(
        reorderedOrder: event.order,
        orders: state.orders,
      ));
    } catch (e) {
      emit(OrderHistoryError(
        message: 'Failed to reorder: $e',
        orders: state.orders,
      ));
    }
  }

  /// Delete a specific order from history
  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderHistoryState> emit,
  ) async {
    try {
      await _repository.deleteOrder(event.orderId);

      final orders = await _repository.loadOrderHistory();

      emit(OrderDeleted(
        deletedOrderId: event.orderId,
        orders: orders,
      ));
    } catch (e) {
      emit(OrderHistoryError(
        message: 'Failed to delete order: $e',
        orders: state.orders,
      ));
    }
  }

  /// Clear all order history
  Future<void> _onClearAllOrders(
    ClearAllOrders event,
    Emitter<OrderHistoryState> emit,
  ) async {
    try {
      await _repository.clearHistory();

      emit(OrderHistoryCleared());
    } catch (e) {
      emit(OrderHistoryError(
        message: 'Failed to clear order history: $e',
        orders: state.orders,
      ));
    }
  }
}
