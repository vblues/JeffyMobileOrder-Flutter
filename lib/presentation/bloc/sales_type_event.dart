import '../../data/models/sales_type_model.dart';

/// Base class for all sales type events
abstract class SalesTypeEvent {}

/// Select a sales type
class SelectSalesType extends SalesTypeEvent {
  final SalesType salesType;

  SelectSalesType(this.salesType);
}

/// Set pickup time for scheduled orders
class SetPickupTime extends SalesTypeEvent {
  final DateTime pickupTime;

  SetPickupTime(this.pickupTime);
}

/// Toggle ASAP mode
class ToggleASAP extends SalesTypeEvent {
  final bool isASAP;

  ToggleASAP(this.isASAP);
}

/// Set pager number for dine-in orders
class SetPagerNumber extends SalesTypeEvent {
  final String pagerNumber;

  SetPagerNumber(this.pagerNumber);
}

/// Confirm and proceed to payment
class ConfirmSalesType extends SalesTypeEvent {}

/// Reset selection
class ResetSalesType extends SalesTypeEvent {}
