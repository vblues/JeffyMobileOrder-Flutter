import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/models/store_info_model.dart';
import 'package:mobileorder/presentation/bloc/store_bloc.dart';
import 'package:mobileorder/presentation/bloc/store_event.dart';
import 'package:mobileorder/presentation/bloc/store_state.dart';
import 'package:mobileorder/data/repositories/store_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  group('StoreBloc', () {
    late MockStoreRepository mockRepository;

    setUp(() {
      mockRepository = MockStoreRepository();
    });

    test('initial state is StoreInitial', () {
      // Arrange
      final bloc = StoreBloc(storeRepository: mockRepository);

      // Assert
      expect(bloc.state, isA<StoreInitial>());

      bloc.close();
    });

    blocTest<StoreBloc, StoreState>(
      'emits [StoreLoading, StoreLoaded] when FetchStoreData succeeds',
      build: () {
        // Arrange
        final mockResponse = StoreInfoResponse(
          resultCode: '200',
          storeInfos: [
            StoreInfo(
              storeId: 12,
              storeSn: '003002',
              storeNote: '{}',
              storeName: '{"en":"Test Store"}',
            ),
          ],
          payTypeInfo: [],
          saleTypeInfo: [],
        );

        when(() => mockRepository.fetchStoreData(any()))
            .thenAnswer((_) async => mockResponse);

        return StoreBloc(storeRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const FetchStoreData('test-store-id')),
      expect: () => [
        isA<StoreLoading>(),
        isA<StoreLoaded>()
            .having((state) => state.storeInfo?.storeId, 'storeId', equals(12))
            .having((state) => state.storeInfo?.storeSn, 'storeSn', equals('003002')),
      ],
      verify: (_) {
        verify(() => mockRepository.fetchStoreData('test-store-id')).called(1);
      },
    );

    blocTest<StoreBloc, StoreState>(
      'emits [StoreLoading, StoreError] when FetchStoreData fails',
      build: () {
        // Arrange
        when(() => mockRepository.fetchStoreData(any()))
            .thenThrow(Exception('Network error'));

        return StoreBloc(storeRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const FetchStoreData('test-store-id')),
      expect: () => [
        isA<StoreLoading>(),
        isA<StoreError>()
            .having((state) => state.message, 'message', contains('Network error')),
      ],
    );

    blocTest<StoreBloc, StoreState>(
      'handles multiple FetchStoreData events sequentially',
      build: () {
        final mockResponse1 = StoreInfoResponse(
          resultCode: '200',
          storeInfos: [
            StoreInfo(
              storeId: 1,
              storeSn: '001',
              storeNote: '{}',
              storeName: '{"en":"Store 1"}',
            ),
          ],
          payTypeInfo: [],
          saleTypeInfo: [],
        );

        final mockResponse2 = StoreInfoResponse(
          resultCode: '200',
          storeInfos: [
            StoreInfo(
              storeId: 2,
              storeSn: '002',
              storeNote: '{}',
              storeName: '{"en":"Store 2"}',
            ),
          ],
          payTypeInfo: [],
          saleTypeInfo: [],
        );

        when(() => mockRepository.fetchStoreData('store-1'))
            .thenAnswer((_) async => mockResponse1);
        when(() => mockRepository.fetchStoreData('store-2'))
            .thenAnswer((_) async => mockResponse2);

        return StoreBloc(storeRepository: mockRepository);
      },
      act: (bloc) => bloc
        ..add(const FetchStoreData('store-1'))
        ..add(const FetchStoreData('store-2')),
      expect: () => [
        isA<StoreLoading>(),
        isA<StoreLoaded>().having((s) => s.storeInfo?.storeId, 'storeId', 1),
        isA<StoreLoading>(),
        isA<StoreLoaded>().having((s) => s.storeInfo?.storeId, 'storeId', 2),
      ],
    );
  });

  group('StoreState', () {
    test('StoreLoaded.storeInfo returns first store if available', () {
      // Arrange
      final response = StoreInfoResponse(
        resultCode: '200',
        storeInfos: [
          StoreInfo(
            storeId: 1,
            storeSn: '001',
            storeNote: '{}',
            storeName: '{}',
          ),
        ],
        payTypeInfo: [],
        saleTypeInfo: [],
      );

      final state = StoreLoaded(response);

      // Act & Assert
      expect(state.storeInfo, isNotNull);
      expect(state.storeInfo?.storeId, equals(1));
    });

    test('StoreLoaded.storeInfo returns null if no stores', () {
      // Arrange
      final response = StoreInfoResponse(
        resultCode: '200',
        storeInfos: [],
        payTypeInfo: [],
        saleTypeInfo: [],
      );

      final state = StoreLoaded(response);

      // Act & Assert
      expect(state.storeInfo, isNull);
    });
  });
}
