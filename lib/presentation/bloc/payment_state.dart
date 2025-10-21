import '../../data/models/payment_model.dart';

/// Payment states
abstract class PaymentState {
  const PaymentState();
}

/// Initial state - no payment method selected
class PaymentInitial extends PaymentState {
  const PaymentInitial();

  @override
  String toString() => 'PaymentInitial()';
}

/// Payment method selected
class PaymentMethodSelected extends PaymentState {
  final PaymentSelection selection;

  const PaymentMethodSelected(this.selection);

  @override
  String toString() => 'PaymentMethodSelected(selection: $selection)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethodSelected && other.selection == selection;
  }

  @override
  int get hashCode => selection.hashCode;
}

/// Payment confirmed - ready to proceed to processing
class PaymentConfirmed extends PaymentState {
  final PaymentSelection selection;

  const PaymentConfirmed(this.selection);

  @override
  String toString() => 'PaymentConfirmed(selection: $selection)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentConfirmed && other.selection == selection;
  }

  @override
  int get hashCode => selection.hashCode;
}

/// Payment error
class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  String toString() => 'PaymentError(message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
