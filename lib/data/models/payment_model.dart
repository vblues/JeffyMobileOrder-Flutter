/// Payment method selection models
///
/// For MVP: Only Pay at Counter (PAC) and Credit Card
/// Excludes: Loyalty payments, vouchers, staff discount

enum PaymentMethod {
  payAtCounter,
  creditCard,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.payAtCounter:
        return 'Pay at Counter';
      case PaymentMethod.creditCard:
        return 'Pay by Credit Card';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.payAtCounter:
        return 'Complete your payment when you collect your order';
      case PaymentMethod.creditCard:
        return 'Pay securely online with your credit/debit card';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.payAtCounter:
        return '💵'; // Cash emoji
      case PaymentMethod.creditCard:
        return '💳'; // Credit card emoji
    }
  }
}

/// Payment selection state
class PaymentSelection {
  final PaymentMethod? method;
  final bool isValid;

  const PaymentSelection({
    this.method,
    this.isValid = false,
  });

  PaymentSelection copyWith({
    PaymentMethod? method,
    bool? isValid,
  }) {
    return PaymentSelection(
      method: method ?? this.method,
      isValid: isValid ?? this.isValid,
    );
  }

  // Factory: Create from JSON (for persistence)
  factory PaymentSelection.fromJson(Map<String, dynamic> json) {
    final methodStr = json['method'] as String?;
    PaymentMethod? method;
    if (methodStr != null) {
      method = PaymentMethod.values.firstWhere(
        (e) => e.toString() == methodStr,
        orElse: () => PaymentMethod.payAtCounter,
      );
    }

    return PaymentSelection(
      method: method,
      isValid: json['isValid'] as bool? ?? false,
    );
  }

  // Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'method': method?.toString(),
      'isValid': isValid,
    };
  }

  @override
  String toString() => 'PaymentSelection(method: $method, isValid: $isValid)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentSelection &&
        other.method == method &&
        other.isValid == isValid;
  }

  @override
  int get hashCode => method.hashCode ^ isValid.hashCode;
}
