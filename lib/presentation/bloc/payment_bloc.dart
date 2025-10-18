import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/sales_type_model.dart';
import '../../data/repositories/payment_repository_impl.dart';

// Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class SelectPaymentMethod extends PaymentEvent {
  final int paymentMethodId;

  const SelectPaymentMethod(this.paymentMethodId);

  @override
  List<Object?> get props => [paymentMethodId];
}

class SubmitOrder extends PaymentEvent {
  final List<CartItem> cartItems;
  final SalesTypeSelection salesTypeSelection;
  final int paymentMethodId;

  const SubmitOrder({
    required this.cartItems,
    required this.salesTypeSelection,
    required this.paymentMethodId,
  });

  @override
  List<Object?> get props => [cartItems, salesTypeSelection, paymentMethodId];
}

// States
abstract class PaymentState extends Equatable {
  final int? selectedPaymentMethod;

  const PaymentState({this.selectedPaymentMethod});

  @override
  List<Object?> get props => [selectedPaymentMethod];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial() : super(selectedPaymentMethod: null);
}

class PaymentMethodSelected extends PaymentState {
  const PaymentMethodSelected(int paymentMethodId)
      : super(selectedPaymentMethod: paymentMethodId);
}

class PaymentSubmitting extends PaymentState {
  const PaymentSubmitting(int? paymentMethodId)
      : super(selectedPaymentMethod: paymentMethodId);
}

class PaymentSubmitted extends PaymentState {
  final String sessionId;
  final String cloudOrderNumber;
  final bool requiresGateway; // true for credit card

  const PaymentSubmitted({
    required this.sessionId,
    required this.cloudOrderNumber,
    required this.requiresGateway,
    int? paymentMethodId,
  }) : super(selectedPaymentMethod: paymentMethodId);

  @override
  List<Object?> get props => [
        sessionId,
        cloudOrderNumber,
        requiresGateway,
        selectedPaymentMethod,
      ];
}

class PaymentSuccess extends PaymentState {
  final String cloudOrderNumber;

  const PaymentSuccess({
    required this.cloudOrderNumber,
    int? paymentMethodId,
  }) : super(selectedPaymentMethod: paymentMethodId);

  @override
  List<Object?> get props => [cloudOrderNumber, selectedPaymentMethod];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message, int? paymentMethodId)
      : super(selectedPaymentMethod: paymentMethodId);

  @override
  List<Object?> get props => [message, selectedPaymentMethod];
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;

  PaymentBloc(this._repository) : super(const PaymentInitial()) {
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<SubmitOrder>(_onSubmitOrder);
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentMethodSelected(event.paymentMethodId));
  }

  Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentSubmitting(event.paymentMethodId));

      final response = await _repository.submitOrder(
        cartItems: event.cartItems,
        salesTypeSelection: event.salesTypeSelection,
        paymentMethodId: event.paymentMethodId,
      );

      // Check response
      final resultCode = response['result_code']?.toString() ?? '500';
      if (resultCode != '200') {
        final errorMsg = response['desc']?.toString() ?? 'Order submission failed';
        emit(PaymentError(errorMsg, event.paymentMethodId));
        return;
      }

      final sessionId = response['sessionID']?.toString() ?? '';
      final cloudOrderNumber = response['cloud_order_number']?.toString() ?? '';

      // Check if payment method requires gateway (credit card)
      final requiresGateway = event.paymentMethodId == 60;

      if (requiresGateway && sessionId.isEmpty) {
        emit(PaymentError('No session ID received for payment gateway', event.paymentMethodId));
        return;
      }

      emit(PaymentSubmitted(
        sessionId: sessionId,
        cloudOrderNumber: cloudOrderNumber,
        requiresGateway: requiresGateway,
        paymentMethodId: event.paymentMethodId,
      ));

      // For pay at counter (ID 23 or 999), order is complete immediately
      if (event.paymentMethodId == 23 || event.paymentMethodId == 999) {
        emit(PaymentSuccess(
          cloudOrderNumber: cloudOrderNumber,
          paymentMethodId: event.paymentMethodId,
        ));
      }
    } catch (e) {
      emit(PaymentError(e.toString(), event.paymentMethodId));
    }
  }
}
