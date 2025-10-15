import 'package:equatable/equatable.dart';
import '../../data/models/store_info_model.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {}

class StoreLoading extends StoreState {}

class StoreLoaded extends StoreState {
  final StoreInfoResponse storeInfoResponse;

  const StoreLoaded(this.storeInfoResponse);

  @override
  List<Object?> get props => [storeInfoResponse];

  StoreInfo? get storeInfo =>
      storeInfoResponse.storeInfos.isNotEmpty ? storeInfoResponse.storeInfos.first : null;
}

class StoreError extends StoreState {
  final String message;

  const StoreError(this.message);

  @override
  List<Object?> get props => [message];
}
