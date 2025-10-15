import '../../data/models/menu_model.dart';
import '../../data/models/product_model.dart';

abstract class MenuState {}

/// Initial state before loading
class MenuInitial extends MenuState {}

/// Loading menu and products
class MenuLoading extends MenuState {}

/// Menu and products loaded successfully
class MenuLoaded extends MenuState {
  final List<MenuCategory> categories;
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final int? selectedParentCategoryId;
  final int? selectedCategoryId;
  final List<MenuCategory> subcategories;
  final String searchQuery;

  MenuLoaded({
    required this.categories,
    required this.allProducts,
    required this.filteredProducts,
    this.selectedParentCategoryId,
    this.selectedCategoryId,
    this.subcategories = const [],
    this.searchQuery = '',
  });

  /// Get parent categories (top-level categories)
  List<MenuCategory> get parentCategories =>
      categories.where((cat) => cat.isParent).toList();

  /// Check if subcategories should be shown
  bool get shouldShowSubcategories => subcategories.isNotEmpty;

  /// Get products for the currently selected category
  List<Product> get displayProducts {
    if (searchQuery.isNotEmpty) {
      return filteredProducts
          .where((product) =>
              product.productNameEn.toLowerCase().contains(searchQuery.toLowerCase()) ||
              product.productNameCn.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    return filteredProducts;
  }

  /// Check if a specific parent category is selected
  bool isParentCategorySelected(int categoryId) => selectedParentCategoryId == categoryId;

  /// Check if a specific (sub)category is selected
  bool isCategorySelected(int categoryId) => selectedCategoryId == categoryId;

  /// Create a copy with updated fields
  MenuLoaded copyWith({
    List<MenuCategory>? categories,
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    Object? selectedParentCategoryId = const _Undefined(),
    Object? selectedCategoryId = const _Undefined(),
    List<MenuCategory>? subcategories,
    String? searchQuery,
  }) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      selectedParentCategoryId: selectedParentCategoryId is _Undefined
          ? this.selectedParentCategoryId
          : selectedParentCategoryId as int?,
      selectedCategoryId: selectedCategoryId is _Undefined
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      subcategories: subcategories ?? this.subcategories,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class _Undefined {
  const _Undefined();
}

/// Error loading menu
class MenuError extends MenuState {
  final String message;

  MenuError(this.message);
}
