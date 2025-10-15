import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../data/datasources/menu_remote_datasource.dart';
import '../../data/models/combo_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_attribute_model.dart';
import '../../data/models/store_credentials_model.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_event.dart';
import '../bloc/menu_state.dart';
import '../widgets/web_safe_image.dart';
import 'product_detail_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>( future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Load store credentials from cache
        final credentialsJson = snapshot.data!.getString(StorageKeys.storeCredentials);
        final storeInfoJson = snapshot.data!.getString(StorageKeys.storeInfo);

        if (credentialsJson == null || storeInfoJson == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Menu'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Store Data Found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please scan a QR code at your table or counter to view the menu.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Parse credentials and store info from JSON
        final credentials = StoreCredentialsModel.fromJsonString(credentialsJson);
        final storeInfoData = json.decode(storeInfoJson) as Map<String, dynamic>;
        final storeId = storeInfoData['id'] as int? ?? 0;

        // Extract store name and brand color
        final storeName = _extractStoreName(storeInfoData);
        final brandColor = _extractBrandColor(storeInfoData);

        return BlocProvider(
          create: (context) => MenuBloc(
            menuRepository: MenuRepository(
              remoteDataSource: MenuRemoteDataSource(),
              sharedPreferences: snapshot.data!,
            ),
            credentials: credentials,
            storeId: storeId,
          )..add(LoadMenu()),
          child: _MenuPageView(
            storeName: storeName,
            brandColor: brandColor,
          ),
        );
      },
    );
  }

  static String _extractStoreName(Map<String, dynamic> storeInfoData) {
    try {
      final storeNameJson = storeInfoData['storeName'] ?? storeInfoData['store_name'];
      if (storeNameJson is String) {
        final nameMap = json.decode(storeNameJson) as Map<String, dynamic>;
        return nameMap['en'] as String? ?? nameMap['cn'] as String? ?? 'Menu';
      }
      return 'Menu';
    } catch (e) {
      return 'Menu';
    }
  }

  static String _extractBrandColor(Map<String, dynamic> storeInfoData) {
    try {
      final storeNoteJson = storeInfoData['storeNote'] ?? storeInfoData['store_note'];
      if (storeNoteJson is String) {
        final noteMap = json.decode(storeNoteJson) as Map<String, dynamic>;
        return noteMap['LandingPage']?['TopBarColorCode'] as String? ?? '#996600';
      }
      return '#996600';
    } catch (e) {
      return '#996600';
    }
  }
}

class _MenuPageView extends StatefulWidget {
  final String storeName;
  final String brandColor;

  const _MenuPageView({
    required this.storeName,
    required this.brandColor,
  });

  @override
  State<_MenuPageView> createState() => _MenuPageViewState();
}

class _MenuPageViewState extends State<_MenuPageView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<MenuBloc>().add(SearchProducts(value));
                },
              )
            : Text(widget.storeName),
        backgroundColor: _parseColor(widget.brandColor),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<MenuBloc>().add(SearchProducts(''));
                }
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<MenuBloc, MenuState>(
        builder: (context, state) {
          if (state is MenuLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading menu...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (state is MenuError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Menu',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MenuBloc>().add(RefreshMenu());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MenuLoaded) {
            return Column(
              children: [
                // Parent category chips
                _buildCategoryChips(context, state),
                const Divider(height: 1),
                // Subcategory chips (if any)
                if (state.shouldShowSubcategories) ...[
                  _buildSubcategoryChips(context, state),
                  const Divider(height: 1),
                ],
                // Product grid
                Expanded(
                  child: _buildProductGrid(context, state),
                ),
              ],
            );
          }

          return const Center(
            child: Text('Ready to load menu'),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, MenuLoaded state) {
    final parentCategories = state.parentCategories;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // "All" category
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: state.selectedParentCategoryId == null && state.selectedCategoryId == null
                ? ElevatedButton(
                    onPressed: () {
                      context.read<MenuBloc>().add(SelectCategory(null));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('All'),
                  )
                : OutlinedButton(
                    onPressed: () {
                      context.read<MenuBloc>().add(SelectCategory(null));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('All'),
                  ),
          ),
          // Category buttons
          ...parentCategories.map((category) {

            final isSelected = state.isParentCategorySelected(category.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isSelected
                  ? ElevatedButton(
                      onPressed: () {
                        context.read<MenuBloc>().add(SelectCategory(category.id));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(category.catNameEn),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        context.read<MenuBloc>().add(SelectCategory(category.id));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(category.catNameEn),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubcategoryChips(BuildContext context, MenuLoaded state) {
    final subcategories = state.subcategories;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: subcategories.map((subcategory) {
          final isSelected = state.isCategorySelected(subcategory.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isSelected
                ? ElevatedButton(
                    onPressed: () {
                      context.read<MenuBloc>().add(SelectCategory(subcategory.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(subcategory.catNameEn),
                  )
                : OutlinedButton(
                    onPressed: () {
                      context.read<MenuBloc>().add(SelectCategory(subcategory.id));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[700]!),
                    ),
                    child: Text(subcategory.catNameEn),
                  ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, MenuLoaded state) {
    final products = state.displayProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No products found for "${state.searchQuery}"'
                  : 'No products in this category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MenuBloc>().add(RefreshMenu());
        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.52,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Get product attributes and combo categories from menu state
    final menuState = context.read<MenuBloc>().state;
    final attributes = menuState is MenuLoaded
        ? menuState.getProductAttributes(product.productId)
        : <ProductAttribute>[];
    // Get only selectable combo categories (categories after the first matcher category)
    final comboCategories = menuState is MenuLoaded
        ? menuState.getSelectableComboCategories(product.productId)
        : <ComboCategory>[];
    final comboProductsMap = menuState is MenuLoaded
        ? menuState.comboProductsMap
        : <int, Product>{};
    final productAttributesMap = menuState is MenuLoaded
        ? menuState.productAttributes
        : <int, List<ProductAttribute>>{};

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: product,
                attributes: attributes,
                comboCategories: comboCategories,
                comboProductsMap: comboProductsMap,
                productAttributesMap: productAttributesMap,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AspectRatio(
              aspectRatio: 1.0,
              child: product.secureProductPic != null
                  ? WebSafeImage(
                      imageUrl: product.secureProductPic!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, size: 48),
                    ),
            ),
            // Product details section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name - Fixed height to accommodate 2 lines
                  SizedBox(
                    height: 42,
                    child: Text(
                      product.productNameEn,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Product price - Always visible
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (!product.isTakeOutAvailable)
                          Icon(
                            Icons.dining,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Add to cart button - Always visible
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              product: product,
                              attributes: attributes,
                              comboCategories: comboCategories,
                              comboProductsMap: comboProductsMap,
                              productAttributesMap: productAttributesMap,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parse hex color string to Flutter Color
  Color _parseColor(String hexColor) {
    try {
      // Remove # if present and parse
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse(hex, radix: 16) + 0xFF000000);
    } catch (e) {
      // Fallback to default orange color
      return const Color(0xFF996600);
    }
  }
}
