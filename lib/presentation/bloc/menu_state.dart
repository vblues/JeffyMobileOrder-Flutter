import '../../data/models/menu_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_attribute_model.dart';
import '../../data/models/combo_model.dart';

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
  final Map<int, List<ProductAttribute>> productAttributes; // productId -> attributes
  final List<ComboActivity> comboActivities; // Available combo activities
  final Map<int, Product> comboProductsMap; // productId -> combo product details
  final int? selectedParentCategoryId;
  final int? selectedCategoryId;
  final List<MenuCategory> subcategories;
  final String searchQuery;

  MenuLoaded({
    required this.categories,
    required this.allProducts,
    required this.filteredProducts,
    this.productAttributes = const {},
    this.comboActivities = const [],
    this.comboProductsMap = const {},
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

  /// Get attributes for a specific product
  List<ProductAttribute> getProductAttributes(int productId) {
    return productAttributes[productId] ?? [];
  }

  /// Get combo activities applicable to a specific product
  /// The first category acts as a "matcher" - if the product is in the first category,
  /// then the product has combo options
  /// Returns list of combo activities where this product appears in the FIRST category only
  List<ComboActivity> getProductCombos(int productId) {
    return comboActivities.where((activity) {
      // Check if activity has at least 2 categories (first for matching, rest for selection)
      if (activity.categories.length < 2) return false;

      // Check if product is in the FIRST category (index 0) - this is the matcher
      return activity.categories[0].containsProductId(productId);
    }).toList();
  }

  /// Get selectable combo categories for a specific product
  /// Returns only the categories AFTER the first one (index 1 onwards)
  /// The first category is just a matcher, not for selection
  List<ComboCategory> getSelectableComboCategories(int productId) {
    final List<ComboCategory> selectableCategories = [];

    for (final activity in comboActivities) {
      // Check if activity has at least 2 categories
      if (activity.categories.length < 2) continue;

      // Check if product is in the FIRST category (matcher)
      if (activity.categories[0].containsProductId(productId)) {
        // Add categories from index 1 onwards (these are selectable)
        for (int i = 1; i < activity.categories.length; i++) {
          selectableCategories.add(activity.categories[i]);
        }
      }
    }

    return selectableCategories;
  }

  /// Check if a product has combo options
  bool hasComboOptions(int productId) {
    return getProductCombos(productId).isNotEmpty;
  }

  /// Get combo product details by ID
  Product? getComboProduct(int productId) {
    return comboProductsMap[productId];
  }

  /// Create a copy with updated fields
  MenuLoaded copyWith({
    List<MenuCategory>? categories,
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    Map<int, List<ProductAttribute>>? productAttributes,
    List<ComboActivity>? comboActivities,
    Map<int, Product>? comboProductsMap,
    Object? selectedParentCategoryId = const _Undefined(),
    Object? selectedCategoryId = const _Undefined(),
    List<MenuCategory>? subcategories,
    String? searchQuery,
  }) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      productAttributes: productAttributes ?? this.productAttributes,
      comboActivities: comboActivities ?? this.comboActivities,
      comboProductsMap: comboProductsMap ?? this.comboProductsMap,
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
