import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart' as app;
import '../../core/constants/storage_keys.dart';
import '../../data/datasources/menu_remote_datasource.dart';
import '../../data/models/combo_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_attribute_model.dart';
import '../../data/models/store_credentials_model.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_event.dart';
import '../bloc/menu_state.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
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

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => MenuBloc(
                menuRepository: MenuRepository(
                  remoteDataSource: MenuRemoteDataSource(),
                  sharedPreferences: snapshot.data!,
                ),
                credentials: credentials,
                storeId: storeId,
              )..add(LoadMenu()),
            ),
            BlocProvider(
              create: (context) => CartBloc(
                CartRepository(snapshot.data!),
              )..add(LoadCart()),
            ),
          ],
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

class _MenuPageViewState extends State<_MenuPageView> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      app.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    app.routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when a route has been popped and this route is now visible
    // This is triggered when returning from CartPage
    context.read<CartBloc>().add(LoadCart());
  }

  @override
  void didPush() {
    // Called when this route has been pushed
  }

  @override
  void didPop() {
    // Called when this route has been popped
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed on top of this route
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
          // Search button
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
          // Cart button with badge
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final itemCount = cartState.totalItemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      context.push('/cart');
                    },
                  ),
                  // Badge showing item count
                  if (itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            itemCount > 9 ? '9+' : itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
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

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        // Calculate cart items per category
        int getCategoryCartCount(int categoryId) {
          final categoryProductIds = state.allProducts
              .where((p) => p.cateId == categoryId)
              .map((p) => p.productId)
              .toSet();
          return cartState.items
              .where((item) => categoryProductIds.contains(item.product.productId))
              .fold(0, (sum, item) => sum + item.quantity);
        }

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
                final cartCount = getCategoryCartCount(category.id);

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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.catNameEn),
                              if (cartCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cartCount.toString(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            context.read<MenuBloc>().add(SelectCategory(category.id));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.catNameEn),
                              if (cartCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cartCount.toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                );
              }),
            ],
          ),
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid: 2 columns on mobile, 3+ on larger screens
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : 2;

          // Fixed card height calculation to match _buildProductCard:
          // Card height = imageWidth + detailsHeight
          // detailsHeight = 160px (24 padding + 60 name + 14 spacing + 24 price + 38 button)
          // Aspect ratio = W / (W + 160)
          // For mobile (W≈170): 170/(170+160) = 0.515
          // For tablet (W≈230): 230/(230+160) = 0.590
          // For desktop (W≈200): 200/(200+160) = 0.556
          const detailsHeight = 160.0;

          // Calculate width per item
          final totalSpacing = 16.0 * (crossAxisCount - 1) + 32.0; // crossSpacing + horizontal padding
          final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
          final aspectRatio = itemWidth / (itemWidth + detailsHeight);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, product);
            },
          );
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

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        // Calculate total quantity of this product in cart
        final quantityInCart = cartState.items
            .where((item) => item.product.productId == product.productId)
            .fold(0, (sum, item) => sum + item.quantity);

        return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fixed dimensions for card sections
          final imageSize = constraints.maxWidth; // Square image
          const nameHeight = 60.0; // Fixed height for 3 lines of text (14px * 1.3 line height * 3 lines + padding)
          const priceHeight = 24.0; // Fixed height for price row
          const buttonHeight = 38.0; // Fixed height for button
          const verticalPadding = 12.0 * 2; // Top and bottom padding
          const verticalSpacing = 6.0 + 8.0; // Spacing between elements

          // Total details section height
          const detailsHeight = verticalPadding + nameHeight + verticalSpacing + priceHeight + buttonHeight;

          return SizedBox(
            height: imageSize + detailsHeight, // Fixed total height
            child: InkWell(
              onTap: () {
                // Get CartBloc from parent context
                final cartBloc = context.read<CartBloc>();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: cartBloc,
                      child: ProductDetailPage(
                        product: product,
                        attributes: attributes,
                        comboCategories: comboCategories,
                        comboProductsMap: comboProductsMap,
                        productAttributesMap: productAttributesMap,
                      ),
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product image with cart quantity badge - FIXED HEIGHT
                  SizedBox(
                    width: imageSize,
                    height: imageSize, // Square image
                    child: Stack(
                      children: [
                        // Product image
                        product.secureProductPic != null
                            ? WebSafeImage(
                                imageUrl: product.secureProductPic!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.restaurant, size: 48),
                              ),
                        // Cart quantity badge
                        if (quantityInCart > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    quantityInCart.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Product details section - FIXED HEIGHT
                  SizedBox(
                    height: detailsHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product name - FIXED HEIGHT for 3 lines
                          SizedBox(
                            height: nameHeight,
                            child: Text(
                              product.productNameEn,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Product price with icon - FIXED HEIGHT
                          SizedBox(
                            height: priceHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.formattedPrice,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                if (!product.isTakeOutAvailable)
                                  Icon(
                                    Icons.dining,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Add to cart button - FIXED HEIGHT
                          SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: () {
                                // Get CartBloc from parent context
                                final cartBloc = context.read<CartBloc>();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider.value(
                                      value: cartBloc,
                                      child: ProductDetailPage(
                                        product: product,
                                        attributes: attributes,
                                        comboCategories: comboCategories,
                                        comboProductsMap: comboProductsMap,
                                        productAttributesMap: productAttributesMap,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
      },
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
