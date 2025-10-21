import '../../data/models/payment_model.dart';

/// Payment events
abstract class PaymentEvent {
  const PaymentEvent();
}

/// Select a payment method
class SelectPaymentMethod extends PaymentEvent {
  final PaymentMethod method;

  const SelectPaymentMethod(this.method);

  @override
  String toString() => 'SelectPaymentMethod(method: $method)';
}

/// Confirm payment selection and proceed
class ConfirmPayment extends PaymentEvent {
  const ConfirmPayment();

  @override
  String toString() => 'ConfirmPayment()';
}

/// Reset payment selection
class ResetPayment extends PaymentEvent {
  const ResetPayment();

  @override
  String toString() => 'ResetPayment()';
}
