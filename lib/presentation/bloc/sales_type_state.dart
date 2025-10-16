import '../../data/models/sales_type_model.dart';

/// Base class for all sales type states
abstract class SalesTypeState {
  final SalesType? selectedSalesType;
  final OrderSchedule? schedule;

  SalesTypeState({
    this.selectedSalesType,
    this.schedule,
  });

  /// Check if selection is complete
  bool get isSelectionComplete {
    if (selectedSalesType == null) return false;

    // Dine-in is always complete (no schedule needed)
    if (selectedSalesType == SalesType.dineIn) return true;

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
  }) : super(selectedSalesType: salesType, schedule: schedule);
}

/// Pickup time selected
class PickupTimeSelected extends SalesTypeState {
  PickupTimeSelected({
    required SalesType salesType,
    required OrderSchedule schedule,
  }) : super(selectedSalesType: salesType, schedule: schedule);
}

/// Selection confirmed
class SalesTypeConfirmed extends SalesTypeState {
  final SalesTypeSelection confirmedSelection;

  SalesTypeConfirmed({
    required this.confirmedSelection,
  }) : super(
          selectedSalesType: confirmedSelection.salesType,
          schedule: confirmedSelection.schedule,
        );
}

/// Error state
class SalesTypeError extends SalesTypeState {
  final String message;

  SalesTypeError({
    required this.message,
    SalesType? salesType,
    OrderSchedule? schedule,
  }) : super(selectedSalesType: salesType, schedule: schedule);
}
