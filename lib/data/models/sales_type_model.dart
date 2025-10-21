/// Sales type options for order delivery
enum SalesType {
  dineIn,
  pickup;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case SalesType.dineIn:
        return 'Dine In';
      case SalesType.pickup:
        return 'Pick-Up';
    }
  }

  /// Icon name for UI
  String get icon {
    switch (this) {
      case SalesType.dineIn:
        return '🍽️';
      case SalesType.pickup:
        return '🥡';
    }
  }

  /// Description for UI
  String get description {
    switch (this) {
      case SalesType.dineIn:
        return 'Dine in at the restaurant';
      case SalesType.pickup:
        return 'Pre-order and pick up at scheduled time';
    }
  }

  /// Convert to API value
  String toApiValue() {
    switch (this) {
      case SalesType.dineIn:
        return 'DINE_IN';
      case SalesType.pickup:
        return 'PICKUP';
    }
  }

  /// Create from API value
  static SalesType fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'DINE_IN':
        return SalesType.dineIn;
      case 'PICKUP':
        return SalesType.pickup;
      default:
        return SalesType.dineIn;
    }
  }
}

/// Order scheduling information
class OrderSchedule {
  final DateTime pickupTime;
  final bool isASAP;

  OrderSchedule({
    required this.pickupTime,
    this.isASAP = false,
  });

  /// Get formatted pickup time string
  String get formattedTime {
    if (isASAP) return 'ASAP';

    final hour = pickupTime.hour;
    final minute = pickupTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final pickupDate = DateTime(pickupTime.year, pickupTime.month, pickupTime.day);

    if (pickupDate == today) {
      return 'Today';
    } else if (pickupDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${pickupTime.day}/${pickupTime.month}/${pickupTime.year}';
    }
  }

  /// Get full formatted string
  String get formattedDateTime {
    if (isASAP) return 'ASAP';
    return '$formattedDate, $formattedTime';
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupTime': pickupTime.toIso8601String(),
      'isASAP': isASAP,
    };
  }

  factory OrderSchedule.fromJson(Map<String, dynamic> json) {
    return OrderSchedule(
      pickupTime: DateTime.parse(json['pickupTime'] as String),
      isASAP: json['isASAP'] as bool? ?? false,
    );
  }

  /// Create ASAP order schedule
  factory OrderSchedule.asap() {
    return OrderSchedule(
      pickupTime: DateTime.now(),
      isASAP: true,
    );
  }

  /// Create scheduled order
  factory OrderSchedule.scheduled(DateTime time) {
    return OrderSchedule(
      pickupTime: time,
      isASAP: false,
    );
  }

  OrderSchedule copyWith({
    DateTime? pickupTime,
    bool? isASAP,
  }) {
    return OrderSchedule(
      pickupTime: pickupTime ?? this.pickupTime,
      isASAP: isASAP ?? this.isASAP,
    );
  }
}

/// Sales type selection state
class SalesTypeSelection {
  final SalesType salesType;
  final OrderSchedule? schedule;
  final String? pagerNumber; // For dine-in orders with pager enabled

  SalesTypeSelection({
    required this.salesType,
    this.schedule,
    this.pagerNumber,
  });

  /// Check if selection is complete and valid
  bool get isValid {
    // Dine-in doesn't need schedule
    if (salesType == SalesType.dineIn) return true;

    // Pickup requires schedule
    if (salesType == SalesType.pickup) return schedule != null;

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'salesType': salesType.toApiValue(),
      'schedule': schedule?.toJson(),
      'pagerNumber': pagerNumber,
    };
  }

  factory SalesTypeSelection.fromJson(Map<String, dynamic> json) {
    return SalesTypeSelection(
      salesType: SalesType.fromApiValue(json['salesType'] as String),
      schedule: json['schedule'] != null
          ? OrderSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
      pagerNumber: json['pagerNumber'] as String?,
    );
  }

  SalesTypeSelection copyWith({
    SalesType? salesType,
    OrderSchedule? schedule,
    String? pagerNumber,
  }) {
    return SalesTypeSelection(
      salesType: salesType ?? this.salesType,
      schedule: schedule ?? this.schedule,
      pagerNumber: pagerNumber ?? this.pagerNumber,
    );
  }
}
