import '../../data/models/sales_type_model.dart';

/// Base class for all sales type states
abstract class SalesTypeState {
  final SalesType? selectedSalesType;
  final OrderSchedule? schedule;
  final String? pagerNumber;

  SalesTypeState({
    this.selectedSalesType,
    this.schedule,
    this.pagerNumber,
  });

  /// Check if selection is complete
  bool get isSelectionComplete {
    if (selectedSalesType == null) return false;

    // Dine-in requires pager number
    if (selectedSalesType == SalesType.dineIn) {
      return pagerNumber != null && pagerNumber!.isNotEmpty;
    }

    // Pickup requires schedule
    if (selectedSalesType == SalesType.pickup) return schedule != null;

    return false;
  }

  /// Get current selection
  SalesTypeSelection? get selection {
    if (selectedSalesType == null) return null;
    return SalesTypeSelection(
      salesType: selectedSalesType!,
      schedule: schedule,
      pagerNumber: pagerNumber,
    );
  }
}

/// Initial state
class SalesTypeInitial extends SalesTypeState {
  SalesTypeInitial() : super();
}

/// Sales type selected
class SalesTypeSelected extends SalesTypeState {
  SalesTypeSelected({
    required SalesType salesType,
    OrderSchedule? schedule,
    String? pagerNumber,
  }) : super(selectedSalesType: salesType, schedule: schedule, pagerNumber: pagerNumber);
}

/// Pickup time selected
class PickupTimeSelected extends SalesTypeState {
  PickupTimeSelected({
    required SalesType salesType,
    required OrderSchedule schedule,
    String? pagerNumber,
  }) : super(selectedSalesType: salesType, schedule: schedule, pagerNumber: pagerNumber);
}

/// Pager number set
class PagerNumberSet extends SalesTypeState {
  PagerNumberSet({
    required SalesType salesType,
    required String pagerNumber,
    OrderSchedule? schedule,
  }) : super(selectedSalesType: salesType, schedule: schedule, pagerNumber: pagerNumber);
}

/// Selection confirmed
class SalesTypeConfirmed extends SalesTypeState {
  final SalesTypeSelection confirmedSelection;

  SalesTypeConfirmed({
    required this.confirmedSelection,
  }) : super(
          selectedSalesType: confirmedSelection.salesType,
          schedule: confirmedSelection.schedule,
          pagerNumber: confirmedSelection.pagerNumber,
        );
}

/// Error state
class SalesTypeError extends SalesTypeState {
  final String message;

  SalesTypeError({
    required this.message,
    SalesType? salesType,
    OrderSchedule? schedule,
    String? pagerNumber,
  }) : super(selectedSalesType: salesType, schedule: schedule, pagerNumber: pagerNumber);
}
