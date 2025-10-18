import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_attribute_model.dart';
import '../../data/models/combo_model.dart';
import '../../data/models/store_credentials_model.dart';
import '../../data/repositories/menu_repository_impl.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository menuRepository;
  final StoreCredentialsModel credentials;
  final int storeId;

  MenuBloc({
    required this.menuRepository,
    required this.credentials,
    required this.storeId,
  }) : super(MenuInitial()) {
    on<LoadMenu>(_onLoadMenu);
    on<SelectCategory>(_onSelectCategory);
    on<RefreshMenu>(_onRefreshMenu);
    on<SearchProducts>(_onSearchProducts);
  }

  /// Handle LoadMenu event
  Future<void> _onLoadMenu(LoadMenu event, Emitter<MenuState> emit) async {
    emit(MenuLoading());

    try {
      // Fetch menu categories
      final menuResponse = await menuRepository.getMenu(
        credentials: credentials,
        storeId: storeId,
        forceRefresh: event.forceRefresh,
      );

      if (!menuResponse.isSuccess) {
        emit(MenuError(menuResponse.desc ?? 'Failed to load menu'));
        return;
      }

      // Fetch products
      final productResponse = await menuRepository.getProductByStore(
        credentials: credentials,
        storeId: storeId,
        forceRefresh: event.forceRefresh,
      );

      if (!productResponse.isSuccess) {
        emit(MenuError(productResponse.desc ?? 'Failed to load products'));
        return;
      }

      // Filter out inactive products
      final activeProducts = productResponse.products
          .where((product) => product.isActive)
          .toList();

      // Fetch product attributes (modifiers)
      Map<int, List<ProductAttribute>> attributesMap = {};
      try {
        final attributeResponse = await menuRepository.getProductAtt(
          credentials: credentials,
          storeId: storeId,
          forceRefresh: event.forceRefresh,
        );

        if (attributeResponse.resultCode == 200) {
          // Build map of product_id -> attributes
          for (final group in attributeResponse.attributes) {
            attributesMap[group.productId] = group.attributes;
          }
        }
      } catch (e) {
        // Continue without attributes if fetch fails
        // This is non-critical, so don't block menu loading
        print('Warning: Failed to load product attributes: $e');
      }

      // Fetch combo activities
      List<ComboActivity> comboActivities = [];
      try {
        final comboResponse = await menuRepository.getActivityComboWithPrice(
          credentials: credentials,
          storeId: storeId,
          forceRefresh: event.forceRefresh,
        );

        if (comboResponse.resultCode == 200) {
          // Filter only active combos
          comboActivities = comboResponse.activities
              .where((activity) => activity.isActive)
              .toList();
        }
      } catch (e) {
        // Continue without combo activities if fetch fails
        print('Warning: Failed to load combo activities: $e');
      }

      // Fetch combo products
      Map<int, Product> comboProductsMap = {};
      try {
        final comboProductsResponse = await menuRepository.getStoreComboProduct(
          credentials: credentials,
          storeId: storeId,
          forceRefresh: event.forceRefresh,
        );

        if (comboProductsResponse.isSuccess) {
          // Build map of product_id -> product for quick lookup
          for (final product in comboProductsResponse.products) {
            comboProductsMap[product.productId] = product;
          }
        }
      } catch (e) {
        // Continue without combo products if fetch fails
        print('Warning: Failed to load combo products: $e');
      }

      emit(MenuLoaded(
        categories: menuResponse.menu,
        allProducts: activeProducts,
        filteredProducts: activeProducts,
        productAttributes: attributesMap,
        comboActivities: comboActivities,
        comboProductsMap: comboProductsMap,
      ));
    } catch (e) {
      emit(MenuError('Error loading menu: ${e.toString()}'));
    }
  }

  /// Handle SelectCategory event
  /// Note: This is now mainly used for tracking scroll position
  /// Actual filtering only happens for search
  void _onSelectCategory(SelectCategory event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;

      // Simply update the selected category tracking
      // No filtering needed since all products are shown in sections
      emit(currentState.copyWith(
        selectedParentCategoryId: event.categoryId,
        selectedCategoryId: event.categoryId,
        subcategories: [],
        searchQuery: '', // Clear search when selecting category
      ));
    }
  }

  /// Handle RefreshMenu event
  Future<void> _onRefreshMenu(RefreshMenu event, Emitter<MenuState> emit) async {
    add(LoadMenu(forceRefresh: true));
  }

  /// Handle SearchProducts event
  void _onSearchProducts(SearchProducts event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;

      emit(currentState.copyWith(
        searchQuery: event.query,
      ));
    }
  }
}
