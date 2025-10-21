import 'dart:convert';
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

class ResetPayment extends PaymentEvent {
  const ResetPayment();
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
  final String? orderNumber; // Store order number

  const PaymentSuccess({
    required this.cloudOrderNumber,
    this.orderNumber,
    int? paymentMethodId,
  }) : super(selectedPaymentMethod: paymentMethodId);

  @override
  List<Object?> get props => [cloudOrderNumber, orderNumber, selectedPaymentMethod];
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
    on<ResetPayment>(_onResetPayment);
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
        // Use displaymsg if available, otherwise use desc
        String errorMsg = response['displaymsg']?.toString() ??
                         response['desc']?.toString() ??
                         'Order submission failed';

        // Parse store_response if available to get more details
        final storeResponse = response['store_response']?.toString();
        if (storeResponse != null && storeResponse.isNotEmpty) {
          try {
            final storeData = json.decode(storeResponse);
            final storeMessage = storeData['Response']?['Message']?.toString();
            if (storeMessage != null && storeMessage.isNotEmpty) {
              errorMsg = '$errorMsg\n\nStore: $storeMessage';
            }
          } catch (e) {
            // Ignore JSON parsing errors
          }
        }

        emit(PaymentError(errorMsg, event.paymentMethodId));
        return;
      }

      final sessionId = response['sessionID']?.toString() ?? '';
      final cloudOrderNumber = response['cloud_order_number']?.toString() ?? '';
      final orderNumber = response['order_number']?.toString();

      // Check if payment method requires gateway (credit card = pay_code 2013)
      final requiresGateway = event.paymentMethodId == 2013;

      if (requiresGateway && sessionId.isEmpty) {
        emit(PaymentError('No session ID received for payment gateway', event.paymentMethodId));
        return;
      }

      // For pay at counter (pay_code 999), order is complete immediately
      if (event.paymentMethodId == 999) {
        emit(PaymentSuccess(
          cloudOrderNumber: cloudOrderNumber,
          orderNumber: orderNumber,
          paymentMethodId: event.paymentMethodId,
        ));
      } else {
        // For credit card, need to show payment gateway
        emit(PaymentSubmitted(
          sessionId: sessionId,
          cloudOrderNumber: cloudOrderNumber,
          requiresGateway: requiresGateway,
          paymentMethodId: event.paymentMethodId,
        ));
      }
    } catch (e) {
      emit(PaymentError(e.toString(), event.paymentMethodId));
    }
  }

  void _onResetPayment(
    ResetPayment event,
    Emitter<PaymentState> emit,
  ) {
    emit(const PaymentInitial());
  }
}
