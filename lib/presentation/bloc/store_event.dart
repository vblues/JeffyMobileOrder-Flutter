import 'package:equatable/equatable.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

class FetchStoreData extends StoreEvent {
  final String storeId;

  const FetchStoreData(this.storeId);

  @override
  List<Object?> get props => [storeId];
}
