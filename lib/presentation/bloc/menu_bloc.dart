import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/menu_model.dart';
import '../../data/models/product_model.dart';
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

      emit(MenuLoaded(
        categories: menuResponse.menu,
        allProducts: activeProducts,
        filteredProducts: activeProducts,
      ));
    } catch (e) {
      emit(MenuError('Error loading menu: ${e.toString()}'));
    }
  }

  /// Handle SelectCategory event
  void _onSelectCategory(SelectCategory event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;

      if (event.categoryId == null) {
        // Show all products, clear selection
        emit(currentState.copyWith(
          filteredProducts: currentState.allProducts,
          selectedParentCategoryId: null,
          selectedCategoryId: null,
          subcategories: [],
          searchQuery: '', // Clear search when selecting category
        ));
        return;
      }

      // Find the selected category
      final categoryId = event.categoryId!; // Safe to use ! here after null check above
      final selectedCategory = _findCategoryById(
        currentState.categories,
        categoryId,
      );

      if (selectedCategory == null) return;

      // Check if this category has children (subcategories)
      if (selectedCategory.hasChildren) {
        // Check if parent category has products
        final parentProducts = currentState.allProducts
            .where((product) => product.cateId == categoryId)
            .toList();

        if (parentProducts.isEmpty && selectedCategory.child.isNotEmpty) {
          // Parent has no products, auto-select first subcategory
          final firstSubcategory = selectedCategory.child.first;
          final firstSubcategoryProducts = currentState.allProducts
              .where((product) => product.cateId == firstSubcategory.id)
              .toList();

          emit(currentState.copyWith(
            selectedParentCategoryId: categoryId,
            selectedCategoryId: firstSubcategory.id,
            subcategories: selectedCategory.child,
            filteredProducts: firstSubcategoryProducts,
            searchQuery: '',
          ));
        } else {
          // Parent has products, show them with subcategories available
          emit(currentState.copyWith(
            selectedParentCategoryId: categoryId,
            selectedCategoryId: null,
            subcategories: selectedCategory.child,
            filteredProducts: parentProducts,
            searchQuery: '',
          ));
        }
      } else {
        // No children, show products for this category
        final filteredProducts = currentState.allProducts
            .where((product) => product.cateId == categoryId)
            .toList();

        // Determine if this is a parent or subcategory
        final isParent = selectedCategory.isParent;

        emit(currentState.copyWith(
          selectedParentCategoryId: isParent ? categoryId : currentState.selectedParentCategoryId,
          selectedCategoryId: categoryId,
          subcategories: isParent ? [] : currentState.subcategories,
          filteredProducts: filteredProducts,
          searchQuery: '',
        ));
      }
    }
  }

  /// Helper method to find a category by ID in the category tree
  MenuCategory? _findCategoryById(List<MenuCategory> categories, int id) {
    for (final category in categories) {
      if (category.id == id) return category;

      // Search in children
      final found = _findCategoryById(category.child, id);
      if (found != null) return found;
    }
    return null;
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
