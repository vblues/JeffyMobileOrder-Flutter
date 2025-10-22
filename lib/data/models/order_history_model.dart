import 'package:uuid/uuid.dart';
import 'cart_item_model.dart';
import 'sales_type_model.dart';

/// Order history item containing full order details
class OrderHistoryItem {
  final String id; // Unique ID for this history item
  final String cloudOrderNumber; // From API response
  final String? orderNumber; // Store order number (if available)
  final DateTime orderDate; // When the order was placed
  final List<CartItem> items; // All cart items from the order
  final SalesTypeSelection salesTypeSelection; // Delivery type and schedule
  final PaymentMethodInfo paymentMethod; // Payment method used
  final double totalPrice; // Total order price

  OrderHistoryItem({
    String? id,
    required this.cloudOrderNumber,
    this.orderNumber,
    DateTime? orderDate,
    required this.items,
    required this.salesTypeSelection,
    required this.paymentMethod,
    required this.totalPrice,
  })  : id = id ?? const Uuid().v4(),
        orderDate = orderDate ?? DateTime.now();

  /// Get formatted order number for display
  String get displayOrderNumber {
    return orderNumber ?? cloudOrderNumber;
  }

  /// Get total item count (sum of all quantities)
  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get unique product count
  int get uniqueItemCount {
    return items.length;
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

    if (orderDay == today) {
      return 'Today';
    } else if (orderDay == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "Jan 15, 2025"
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[orderDate.month - 1]} ${orderDate.day}, ${orderDate.year}';
    }
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = orderDate.hour;
    final minute = orderDate.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  /// Get formatted date and time string
  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cloudOrderNumber': cloudOrderNumber,
      'orderNumber': orderNumber,
      'orderDate': orderDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'salesTypeSelection': salesTypeSelection.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'totalPrice': totalPrice,
    };
  }

  /// Create from JSON
  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: json['id'] as String,
      cloudOrderNumber: json['cloudOrderNumber'] as String,
      orderNumber: json['orderNumber'] as String?,
      orderDate: DateTime.parse(json['orderDate'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      salesTypeSelection: SalesTypeSelection.fromJson(
        json['salesTypeSelection'] as Map<String, dynamic>,
      ),
      paymentMethod: PaymentMethodInfo.fromJson(
        json['paymentMethod'] as Map<String, dynamic>,
      ),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  OrderHistoryItem copyWith({
    String? id,
    String? cloudOrderNumber,
    String? orderNumber,
    DateTime? orderDate,
    List<CartItem>? items,
    SalesTypeSelection? salesTypeSelection,
    PaymentMethodInfo? paymentMethod,
    double? totalPrice,
  }) {
    return OrderHistoryItem(
      id: id ?? this.id,
      cloudOrderNumber: cloudOrderNumber ?? this.cloudOrderNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      salesTypeSelection: salesTypeSelection ?? this.salesTypeSelection,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  String toString() {
    return 'OrderHistoryItem(id: $id, orderNumber: $displayOrderNumber, date: $formattedDateTime, items: ${items.length}, total: \$${totalPrice.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderHistoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Payment method information (simplified for history)
class PaymentMethodInfo {
  final int id;
  final String name;
  final String code;

  PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  @override
  String toString() {
    return name;
  }
}
