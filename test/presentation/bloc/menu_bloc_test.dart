import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobileorder/data/models/menu_model.dart';
import 'package:mobileorder/data/models/product_model.dart';
import 'package:mobileorder/data/models/store_credentials_model.dart';
import 'package:mobileorder/data/repositories/menu_repository_impl.dart';
import 'package:mobileorder/presentation/bloc/menu_bloc.dart';
import 'package:mobileorder/presentation/bloc/menu_event.dart';
import 'package:mobileorder/presentation/bloc/menu_state.dart';

class MockMenuRepository extends Mock implements MenuRepository {}

class FakeStoreCredentialsModel extends Fake implements StoreCredentialsModel {}

void main() {
  late MockMenuRepository mockMenuRepository;
  late StoreCredentialsModel credentials;

  setUpAll(() {
    registerFallbackValue(FakeStoreCredentialsModel());
  });

  setUp(() {
    mockMenuRepository = MockMenuRepository();
    credentials = StoreCredentialsModel(
      appKey: 'test_key',
      appSecret: 'test_secret',
      tenantId: '1013',
      deviceId: '12345',
      apiDomain: 'https://api.example.com',
    );
  });

  group('MenuBloc', () {
    test('initial state is MenuInitial', () {
      final bloc = MenuBloc(
        menuRepository: mockMenuRepository,
        credentials: credentials,
        storeId: 1013,
      );

      expect(bloc.state, isA<MenuInitial>());

      bloc.close();
    });

    blocTest<MenuBloc, MenuState>(
      'emits [MenuLoading, MenuLoaded] when LoadMenu succeeds',
      build: () {
        when(() => mockMenuRepository.getMenu(
              credentials: any(named: 'credentials'),
              storeId: any(named: 'storeId'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => MenuResponse(
              resultCode: '200',
              menu: [
                MenuCategory(
                  id: 1,
                  parentId: 0,
                  catName: '{"cn":"饮料","en":"Beverages"}',
                  categorySn: 'CAT001',
                  sortSn: 1,
                  child: [],
                ),
              ],
              desc: 'success',
            ));

        when(() => mockMenuRepository.getProductByStore(
              credentials: any(named: 'credentials'),
              storeId: any(named: 'storeId'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => ProductResponse(
              resultCode: 200,
              products: [
                Product(
                  status: 1,
                  cid: 1,
                  cateId: 1,
                  productId: 1,
                  productName: '{"cn":"咖啡","en":"Coffee"}',
                  productSn: 'P001',
                  isTakeOut: 1,
                  price: '2.50',
                  sortSn: 1,
                  startTime: '07:00:00',
                  endTime: '22:00:00',
                  ingredientName: '{}',
                  ingredientsId: 1,
                  effectiveStartTime: 0,
                  effectiveEndTime: 9999999999,
                  hasModifiers: 1,
                ),
              ],
              desc: 'success',
            ));

        return MenuBloc(
          menuRepository: mockMenuRepository,
          credentials: credentials,
          storeId: 1013,
        );
      },
      act: (bloc) => bloc.add(LoadMenu()),
      expect: () => [
        isA<MenuLoading>(),
        isA<MenuLoaded>()
            .having((state) => state.categories.length, 'categories length', 1)
            .having((state) => state.allProducts.length, 'products length', 1)
            .having((state) => state.filteredProducts.length, 'filtered products length', 1),
      ],
      verify: (_) {
        verify(() => mockMenuRepository.getMenu(
              credentials: credentials,
              storeId: 1013,
              forceRefresh: false,
            )).called(1);
        verify(() => mockMenuRepository.getProductByStore(
              credentials: credentials,
              storeId: 1013,
              forceRefresh: false,
            )).called(1);
      },
    );

    blocTest<MenuBloc, MenuState>(
      'emits [MenuLoading, MenuError] when getMenu fails',
      build: () {
        when(() => mockMenuRepository.getMenu(
              credentials: any(named: 'credentials'),
              storeId: any(named: 'storeId'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(Exception('Network error'));

        return MenuBloc(
          menuRepository: mockMenuRepository,
          credentials: credentials,
          storeId: 1013,
        );
      },
      act: (bloc) => bloc.add(LoadMenu()),
      expect: () => [
        isA<MenuLoading>(),
        isA<MenuError>().having(
          (state) => state.message,
          'error message',
          contains('Network error'),
        ),
      ],
    );

    blocTest<MenuBloc, MenuState>(
      'filters products when SelectCategory is added',
      build: () {
        return MenuBloc(
          menuRepository: mockMenuRepository,
          credentials: credentials,
          storeId: 1013,
        );
      },
      seed: () => MenuLoaded(
        categories: [
          MenuCategory(
            id: 1,
            parentId: 0,
            catName: '{}',
            categorySn: 'CAT001',
            sortSn: 1,
            child: [],
          ),
          MenuCategory(
            id: 2,
            parentId: 0,
            catName: '{}',
            categorySn: 'CAT002',
            sortSn: 2,
            child: [],
          ),
        ],
        allProducts: [
          Product(
            status: 1,
            cid: 1,
            cateId: 1,
            productId: 1,
            productName: '{}',
            productSn: 'P001',
            isTakeOut: 1,
            price: '2.50',
            sortSn: 1,
            startTime: '07:00:00',
            endTime: '22:00:00',
            ingredientName: '{}',
            ingredientsId: 1,
            effectiveStartTime: 0,
            effectiveEndTime: 9999999999,
            hasModifiers: 1,
          ),
          Product(
            status: 1,
            cid: 2,
            cateId: 2,
            productId: 2,
            productName: '{}',
            productSn: 'P002',
            isTakeOut: 1,
            price: '3.50',
            sortSn: 2,
            startTime: '07:00:00',
            endTime: '22:00:00',
            ingredientName: '{}',
            ingredientsId: 2,
            effectiveStartTime: 0,
            effectiveEndTime: 9999999999,
            hasModifiers: 1,
          ),
        ],
        filteredProducts: [],
      ),
      act: (bloc) => bloc.add(SelectCategory(1)),
      expect: () => [
        isA<MenuLoaded>()
            .having((state) => state.selectedCategoryId, 'selected category', 1)
            .having((state) => state.filteredProducts.length, 'filtered products', 1)
            .having((state) => state.filteredProducts[0].cateId, 'first product category', 1),
      ],
    );

    blocTest<MenuBloc, MenuState>(
      'shows all products when SelectCategory with null is added',
      build: () {
        return MenuBloc(
          menuRepository: mockMenuRepository,
          credentials: credentials,
          storeId: 1013,
        );
      },
      seed: () => MenuLoaded(
        categories: [],
        allProducts: [
          Product(
            status: 1,
            cid: 1,
            cateId: 1,
            productId: 1,
            productName: '{}',
            productSn: 'P001',
            isTakeOut: 1,
            price: '2.50',
            sortSn: 1,
            startTime: '07:00:00',
            endTime: '22:00:00',
            ingredientName: '{}',
            ingredientsId: 1,
            effectiveStartTime: 0,
            effectiveEndTime: 9999999999,
            hasModifiers: 1,
          ),
          Product(
            status: 1,
            cid: 2,
            cateId: 2,
            productId: 2,
            productName: '{}',
            productSn: 'P002',
            isTakeOut: 1,
            price: '3.50',
            sortSn: 2,
            startTime: '07:00:00',
            endTime: '22:00:00',
            ingredientName: '{}',
            ingredientsId: 2,
            effectiveStartTime: 0,
            effectiveEndTime: 9999999999,
            hasModifiers: 1,
          ),
        ],
        filteredProducts: [],
        selectedCategoryId: 1,
      ),
      act: (bloc) => bloc.add(SelectCategory(null)),
      expect: () => [
        isA<MenuLoaded>()
            .having((state) => state.selectedCategoryId, 'selected category', null)
            .having((state) => state.filteredProducts.length, 'filtered products', 2),
      ],
    );

    blocTest<MenuBloc, MenuState>(
      'updates search query when SearchProducts is added',
      build: () {
        return MenuBloc(
          menuRepository: mockMenuRepository,
          credentials: credentials,
          storeId: 1013,
        );
      },
      seed: () => MenuLoaded(
        categories: [],
        allProducts: [],
        filteredProducts: [],
        searchQuery: '',
      ),
      act: (bloc) => bloc.add(SearchProducts('coffee')),
      expect: () => [
        isA<MenuLoaded>().having((state) => state.searchQuery, 'search query', 'coffee'),
      ],
    );

    blocTest<MenuBloc, MenuState>(
      'filters out inactive products when LoadMenu succeeds',
      build: () {
        when(() => mockMenuRepository.getMenu(
              credentials: any(named: 'credentials'),
              storeId: any(named: 'storeId'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => MenuResponse(
              resultCode: '200',
              menu: [],
              desc: 'success',
            ));

        when(() => mockMenuRepository.getProductByStore(
              credentials: any(named: 'credentials'),
              storeId: any(named: 'storeId'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => ProductResponse(
              resultCode: 200,
              products: [
                Product(
                  status: 1, // Active
                  cid: 1,
                  cateId: 1,
                  productId: 1,
                  productName: '{}',
                  productSn: 'P001',
                  isTakeOut: 1,
                  price: '2.50',
                  sortSn: 1,
                  startTime: '07:00:00',
                  endTime: '22:00:00',
                  ingredientName: '{}',
                  ingredientsId: 1,
                  effectiveStartTime: 0,
                  effectiveEndTime: 9999999999,
                  hasModifiers: 1,
                ),
                Product(
                  status: 0, // Inactive
                  cid: 2,
                  cateId: 2,
                  productId: 2,
                  productName: '{}',
                  productSn: 'P002',
                  isTakeOut: 1,
                  price: '3.50',
                  sortSn: 2,
                  startTime: '07:00:00',
                  endTime: '22:00:00',
                  ingredientName: '{}',
                  ingredientsId: 2,
                  effectiveStartTime: 0,
                  effectiveEndTime: 9999999999,
                  hasModifiers: 1,
                ),
              ],
              desc: 'success',
            ));

        return MenuBloc(
          menuRepository: mockMenuRepository,
          credentials: credentials,
          storeId: 1013,
        );
      },
      act: (bloc) => bloc.add(LoadMenu()),
      expect: () => [
        isA<MenuLoading>(),
        isA<MenuLoaded>()
            .having((state) => state.allProducts.length, 'active products only', 1)
            .having((state) => state.allProducts[0].status, 'first product status', 1),
      ],
    );
  });
}
