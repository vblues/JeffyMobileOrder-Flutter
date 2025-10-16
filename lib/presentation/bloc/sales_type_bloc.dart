import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/sales_type_model.dart';
import 'sales_type_event.dart';
import 'sales_type_state.dart';

/// BLoC for sales type selection
class SalesTypeBloc extends Bloc<SalesTypeEvent, SalesTypeState> {
  SalesTypeBloc() : super(SalesTypeInitial()) {
    on<SelectSalesType>(_onSelectSalesType);
    on<SetPickupTime>(_onSetPickupTime);
    on<ToggleASAP>(_onToggleASAP);
    on<ConfirmSalesType>(_onConfirmSalesType);
    on<ResetSalesType>(_onResetSalesType);
  }

  /// Handle sales type selection
  void _onSelectSalesType(SelectSalesType event, Emitter<SalesTypeState> emit) {
    // For dine-in, no schedule needed
    if (event.salesType == SalesType.dineIn) {
      emit(SalesTypeSelected(
        salesType: event.salesType,
        schedule: null,
      ));
      return;
    }

    // For pickup, start with ASAP but allow customization
    if (event.salesType == SalesType.pickup) {
      emit(SalesTypeSelected(
        salesType: event.salesType,
        schedule: OrderSchedule.asap(),
      ));
      return;
    }
  }

  /// Handle pickup time selection
  void _onSetPickupTime(SetPickupTime event, Emitter<SalesTypeState> emit) {
    if (state.selectedSalesType == null) {
      emit(SalesTypeError(
        message: 'Please select a sales type first',
      ));
      return;
    }

    // Validate pickup time is in the future
    final now = DateTime.now();
    if (event.pickupTime.isBefore(now)) {
      emit(SalesTypeError(
        message: 'Pickup time must be in the future',
        salesType: state.selectedSalesType,
        schedule: state.schedule,
      ));
      return;
    }

    final schedule = OrderSchedule.scheduled(event.pickupTime);
    emit(PickupTimeSelected(
      salesType: state.selectedSalesType!,
      schedule: schedule,
    ));
  }

  /// Toggle ASAP mode
  void _onToggleASAP(ToggleASAP event, Emitter<SalesTypeState> emit) {
    if (state.selectedSalesType == null) {
      emit(SalesTypeError(
        message: 'Please select a sales type first',
      ));
      return;
    }

    if (event.isASAP) {
      // Set to ASAP
      emit(SalesTypeSelected(
        salesType: state.selectedSalesType!,
        schedule: OrderSchedule.asap(),
      ));
    } else {
      // Set to 30 minutes from now as default
      final defaultTime = DateTime.now().add(const Duration(minutes: 30));
      emit(PickupTimeSelected(
        salesType: state.selectedSalesType!,
        schedule: OrderSchedule.scheduled(defaultTime),
      ));
    }
  }

  /// Confirm selection and proceed
  void _onConfirmSalesType(ConfirmSalesType event, Emitter<SalesTypeState> emit) {
    if (!state.isSelectionComplete) {
      emit(SalesTypeError(
        message: 'Please complete your selection',
        salesType: state.selectedSalesType,
        schedule: state.schedule,
      ));
      return;
    }

    final selection = state.selection!;
    emit(SalesTypeConfirmed(confirmedSelection: selection));
  }

  /// Reset selection
  void _onResetSalesType(ResetSalesType event, Emitter<SalesTypeState> emit) {
    emit(SalesTypeInitial());
  }
}
