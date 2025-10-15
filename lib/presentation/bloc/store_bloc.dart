import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/store_repository_impl.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreRepository storeRepository;

  StoreBloc({required this.storeRepository}) : super(StoreInitial()) {
    on<FetchStoreData>(_onFetchStoreData);
  }

  Future<void> _onFetchStoreData(
    FetchStoreData event,
    Emitter<StoreState> emit,
  ) async {
    emit(StoreLoading());

    try {
      final storeInfoResponse = await storeRepository.fetchStoreData(event.storeId);
      emit(StoreLoaded(storeInfoResponse));
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }
}
