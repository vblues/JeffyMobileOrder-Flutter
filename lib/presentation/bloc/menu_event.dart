abstract class MenuEvent {}

/// Event to load menu categories and products
class LoadMenu extends MenuEvent {
  final bool forceRefresh;

  LoadMenu({this.forceRefresh = false});
}

/// Event to select a category and filter products
class SelectCategory extends MenuEvent {
  final int? categoryId; // null means "All Products"

  SelectCategory(this.categoryId);
}

/// Event to refresh menu data
class RefreshMenu extends MenuEvent {}

/// Event to search products by name
class SearchProducts extends MenuEvent {
  final String query;

  SearchProducts(this.query);
}
