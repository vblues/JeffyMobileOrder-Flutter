import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_attribute_model.dart';
import '../../data/models/combo_model.dart';
import '../../data/models/cart_item_model.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/web_safe_image.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<ProductAttribute> attributes;
  final List<ComboCategory> comboCategories;
  final Map<int, Product> comboProductsMap;
  final Map<int, List<ProductAttribute>> productAttributesMap;
  final CartItem? cartItemToEdit; // For edit mode

  const ProductDetailPage({
    super.key,
    required this.product,
    this.attributes = const [],
    this.comboCategories = const [],
    this.comboProductsMap = const {},
    this.productAttributesMap = const {},
    this.cartItemToEdit,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  double _totalPrice = 0.0;

  // Track selected modifiers: attId -> List<AttributeValue>
  final Map<int, List<AttributeValue>> _selectedModifiers = {};

  // Track selected combos: categoryTypeNameSn -> List<SelectedComboItem>
  final Map<String, List<SelectedComboItem>> _selectedCombos = {};

  /// Check if we're in edit mode
  bool get isEditMode => widget.cartItemToEdit != null;

  @override
  void initState() {
    super.initState();
    _totalPrice = widget.product.priceValue;

    if (isEditMode) {
      // Load existing selections from cart item
      _initializeFromCartItem();
    } else {
      // Initialize with defaults
      _initializeDefaultModifiers();
      _initializeDefaultCombos();
    }
  }

  /// Initialize default modifiers based on default_choose flag
  void _initializeDefaultModifiers() {
    for (final attribute in widget.attributes) {
      final defaultValues = attribute.values
          .where((val) => val.isDefault)
          .toList();

      if (defaultValues.isNotEmpty) {
        _selectedModifiers[attribute.attId] = defaultValues;
      } else {
        _selectedModifiers[attribute.attId] = [];
      }
    }
    _recalculatePrice();
  }

  /// Initialize default combos based on default_id
  void _initializeDefaultCombos() {
    // For each combo category (already filtered to only selectable ones)
    for (final category in widget.comboCategories) {
      // Initialize empty selection list for this category
      _selectedCombos[category.typeNameSn] = [];

      // If there are default IDs, add them
      for (final defaultId in category.defaultIds) {
        final comboProduct = widget.comboProductsMap[defaultId];
        if (comboProduct != null) {
          final priceAdjustment = category.getPriceAdjustment(defaultId);
          _selectedCombos[category.typeNameSn]!.add(
            SelectedComboItem(
              categoryTypeNameSn: int.tryParse(category.typeNameSn) ?? 0,
              categoryName: category.typeNameEn,
              productId: defaultId,
              productSn: comboProduct.productSn,  // Added
              productName: comboProduct.productNameEn,
              priceAdjustment: priceAdjustment,
            ),
          );
        }
      }
    }
    _recalculatePrice();
  }

  /// Initialize from existing cart item (for edit mode)
  void _initializeFromCartItem() {
    final cartItem = widget.cartItemToEdit!;

    // Rebuild modifiers map from cart modifiers
    for (final attribute in widget.attributes) {
      final matchingModifiers = cartItem.modifiers
          .where((mod) => mod.attId == attribute.attId)
          .map((mod) {
            // Find the matching AttributeValue
            return attribute.values.firstWhere(
              (val) => val.attValId == mod.attValId,
              orElse: () => AttributeValue(
                attValName: mod.attValName,
                attValId: mod.attValId,
                price: mod.price.toString(),
                defaultChoose: 0,
                attValSn: mod.attValSn,
                minNum: 0,
                maxNum: 1,
                sort: 0,
              ),
            );
          })
          .toList();

      _selectedModifiers[attribute.attId] = matchingModifiers;
    }

    // Rebuild combos map from cart combo items
    for (final category in widget.comboCategories) {
      final matchingCombos = cartItem.comboItems
          .where((comboItem) =>
              comboItem.categoryTypeNameSn.toString() == category.typeNameSn ||
              comboItem.categoryName == category.typeNameEn)
          .map((comboItem) {
            return SelectedComboItem(
              categoryTypeNameSn: comboItem.categoryTypeNameSn,
              categoryName: comboItem.categoryName,
              productId: comboItem.productId,
              productSn: comboItem.productSn,
              productName: comboItem.productName,
              priceAdjustment: comboItem.priceAdjustment,
              modifiers: comboItem.modifiers.map((mod) {
                return ComboModifier(
                  attId: mod.attId,
                  attName: mod.attName,
                  attValId: mod.attValId,
                  attValName: mod.attValName,
                  attValSn: mod.attValSn,
                  price: mod.price,
                );
              }).toList(),
            );
          })
          .toList();

      _selectedCombos[category.typeNameSn] = matchingCombos;
    }

    _recalculatePrice();
  }

  /// Recalculate total price including modifiers and combos
  void _recalculatePrice() {
    double price = widget.product.priceValue;

    // Add modifier prices
    for (final modifierList in _selectedModifiers.values) {
      for (final modifier in modifierList) {
        price += modifier.priceValue;
      }
    }

    // Add combo price adjustments AND modifier prices
    for (final comboList in _selectedCombos.values) {
      for (final comboItem in comboList) {
        price += comboItem.totalPrice; // Includes price adjustment + modifiers
      }
    }

    setState(() {
      _totalPrice = price;
    });
  }

  /// Check if all mandatory modifiers and combos are selected
  bool _areAllMandatoryModifiersSelected() {
    // Check modifiers
    for (final attribute in widget.attributes) {
      if (attribute.isMandatory) {
        final selected = _selectedModifiers[attribute.attId] ?? [];
        if (selected.length < attribute.minNum) {
          return false;
        }
      }
    }

    // Check combos
    for (final category in widget.comboCategories) {
      if (category.isMandatory) {
        final selected = _selectedCombos[category.typeNameSn] ?? [];
        if (selected.length < category.minNum) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get count of incomplete mandatory modifiers and combos
  int _getIncompleteMandatoryCount() {
    int count = 0;

    // Count incomplete modifiers
    for (final attribute in widget.attributes) {
      if (attribute.isMandatory) {
        final selected = _selectedModifiers[attribute.attId] ?? [];
        if (selected.length < attribute.minNum) {
          count++;
        }
      }
    }

    // Count incomplete combos
    for (final category in widget.comboCategories) {
      if (category.isMandatory) {
        final selected = _selectedCombos[category.typeNameSn] ?? [];
        if (selected.length < category.minNum) {
          count++;
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Item' : 'Product Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content with gradient indicator
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image with overlay
                      _buildProductImageWithOverlay(),

                      // Product details section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Combos section
                            if (widget.comboCategories.isNotEmpty) _buildCombosSection(),
                            // Modifiers section
                            if (widget.attributes.isNotEmpty) _buildModifiersSection(),
                            // Extra padding at bottom so content isn't hidden
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Gradient indicator at bottom to show more content above
                if (widget.attributes.isNotEmpty || widget.comboCategories.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.9),
                              Colors.white,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Fixed bottom section: Total and Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Incomplete modifiers/combos warning
                    if ((widget.attributes.isNotEmpty || widget.comboCategories.isNotEmpty) &&
                        !_areAllMandatoryModifiersSelected())
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_getIncompleteMandatoryCount()} required selection${_getIncompleteMandatoryCount() > 1 ? "s" : ""} remaining',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_upward, color: Colors.orange[700], size: 18),
                          ],
                        ),
                      ),

                    // Quantity selector
                    _buildQuantitySelector(),
                    const SizedBox(height: 16),

                    // Total price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '\$${(_totalPrice * _quantity).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Add to cart or Update item button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _areAllMandatoryModifiersSelected()
                            ? () {
                                if (isEditMode) {
                                  // Update existing cart item
                                  context.read<CartBloc>().add(
                                        UpdateCartItem(
                                          cartItemId: widget.cartItemToEdit!.id,
                                          selectedModifiers: _selectedModifiers,
                                          selectedCombos: _selectedCombos,
                                        ),
                                      );

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Item updated successfully'),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  // Add to cart
                                  context.read<CartBloc>().add(
                                        AddToCart(
                                          product: widget.product,
                                          quantity: _quantity,
                                          selectedModifiers: _selectedModifiers,
                                          selectedCombos: _selectedCombos,
                                        ),
                                      );

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added $_quantity x ${widget.product.productNameEn} to cart',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }

                                // Navigate back
                                context.pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                        ),
                        child: Text(
                          _areAllMandatoryModifiersSelected()
                              ? (isEditMode ? 'Update Item' : 'Add to Cart')
                              : 'Complete Selections Above',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImageWithOverlay() {
    return Stack(
      children: [
        // Product image
        widget.product.secureProductPic != null
            ? WebSafeImage(
                imageUrl: widget.product.secureProductPic!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              ),

        // Gradient overlay for better text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  widget.product.productNameEn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Product description
                if (widget.product.note != null && widget.product.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.product.note!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrement button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _quantity > 1
                ? () {
                    setState(() {
                      _quantity--;
                    });
                  }
                : null,
            icon: const Icon(Icons.remove),
            color: _quantity > 1 ? Colors.black87 : Colors.grey,
          ),
        ),
        const SizedBox(width: 20),

        // Quantity display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _quantity.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 20),

        // Increment button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _quantity < 99
                ? () {
                    setState(() {
                      _quantity++;
                    });
                  }
                : null,
            icon: const Icon(Icons.add),
            color: _quantity < 99 ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Build combos section showing all combo selections
  Widget _buildCombosSection() {
    // widget.comboCategories already contains only the selectable categories
    // (the first matcher category has been filtered out by MenuState.getSelectableComboCategories)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.comboCategories.map((category) {
        final selectedForThis = _selectedCombos[category.typeNameSn] ?? [];
        final hasSelections = selectedForThis.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: Colors.blue[50],
            child: InkWell(
              onTap: () => _showComboSelectionSheet(category),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category name with mandatory indicator
                          Row(
                            children: [
                              Icon(Icons.set_meal, size: 20, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                category.typeNameEn,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                              ),
                              if (category.isMandatory)
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Show selected items or hint
                          if (hasSelections)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: selectedForThis.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Main combo product
                                      Chip(
                                        label: Text(
                                          '${item.productName}${item.totalPrice != 0 ? " (${item.totalPrice > 0 ? '+' : ''}\$${item.totalPrice.toStringAsFixed(2)})" : ""}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.blue[100],
                                      ),
                                      // Show modifiers if any
                                      if (item.modifiers.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, top: 4),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: item.modifiers.map((modifier) {
                                              return Chip(
                                                label: Text(
                                                  '${modifier.attValName}${modifier.price > 0 ? " (+\$${modifier.price.toStringAsFixed(2)})" : ""}',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                padding: EdgeInsets.zero,
                                                backgroundColor: Colors.blue[50],
                                                visualDensity: VisualDensity.compact,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              category.isMandatory
                                  ? 'Required - Select ${category.minNum}'
                                  : 'Optional - Select up to ${category.maxNum}',
                              style: TextStyle(
                                fontSize: 14,
                                color: category.isMandatory ? Colors.red : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Show bottom sheet for combo selection
  void _showComboSelectionSheet(ComboCategory category) {
    // Get available products for this category
    final availableProducts = category.productIds
        .map((productInfo) => widget.comboProductsMap[productInfo.productId])
        .where((product) => product != null)
        .map((product) => product!)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ComboSelectionSheet(
          category: category,
          availableProducts: availableProducts,
          productAttributesMap: widget.productAttributesMap,
          initialSelections: _selectedCombos[category.typeNameSn] ?? [],
          onConfirm: (selections) {
            setState(() {
              _selectedCombos[category.typeNameSn] = selections;
              _recalculatePrice();
            });
          },
        );
      },
    );
  }

  /// Build modifiers section showing all customization options
  Widget _buildModifiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.attributes.map((attribute) {
        final selectedForThis = _selectedModifiers[attribute.attId] ?? [];
        final hasSelections = selectedForThis.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              onTap: () => _showModifierSelectionSheet(attribute),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Attribute name with mandatory indicator
                          Row(
                            children: [
                              Text(
                                attribute.attNameEn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (attribute.isMandatory)
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Show selected items or hint
                          if (hasSelections)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: selectedForThis.map((val) {
                                return Chip(
                                  label: Text(
                                    '${val.attValNameEn}${val.priceValue > 0 ? " ${val.formattedPrice}" : ""}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              attribute.isMandatory
                                  ? 'Required - Select ${attribute.minNum}'
                                  : 'Optional',
                              style: TextStyle(
                                fontSize: 14,
                                color: attribute.isMandatory ? Colors.red : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Show bottom sheet for modifier selection
  void _showModifierSelectionSheet(ProductAttribute attribute) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ModifierSelectionSheet(
          attribute: attribute,
          initialSelections: _selectedModifiers[attribute.attId] ?? [],
          onConfirm: (selections) {
            setState(() {
              _selectedModifiers[attribute.attId] = selections;
              _recalculatePrice();
            });
          },
        );
      },
    );
  }
}

/// Separate stateful widget for modifier selection sheet
class _ModifierSelectionSheet extends StatefulWidget {
  final ProductAttribute attribute;
  final List<AttributeValue> initialSelections;
  final Function(List<AttributeValue>) onConfirm;

  const _ModifierSelectionSheet({
    required this.attribute,
    required this.initialSelections,
    required this.onConfirm,
  });

  @override
  State<_ModifierSelectionSheet> createState() => _ModifierSelectionSheetState();
}

class _ModifierSelectionSheetState extends State<_ModifierSelectionSheet> {
  late List<AttributeValue> currentSelections;

  @override
  void initState() {
    super.initState();
    currentSelections = List<AttributeValue>.from(widget.initialSelections);
  }

  /// Calculate total modifier price for current selections
  double get _modifierTotal {
    double total = 0.0;
    for (final selection in currentSelections) {
      total += selection.priceValue;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.attribute.attNameEn,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.attribute.isMandatory
                                    ? 'Select ${widget.attribute.minNum}'
                                    : 'Select up to ${widget.attribute.maxNum}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (_modifierTotal > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[300]!),
                                ),
                                child: Text(
                                  '+\$${_modifierTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Options list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.attribute.values.length,
                itemBuilder: (context, index) {
                  final value = widget.attribute.values[index];
                  final isSelected = currentSelections
                      .any((v) => v.attValId == value.attValId);

                  // Use radio button style for single-select (maxNum = 1)
                  if (widget.attribute.maxNum == 1) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          // If already selected and not mandatory, deselect it
                          if (currentSelections.isNotEmpty &&
                              currentSelections.first.attValId == value.attValId &&
                              !widget.attribute.isMandatory) {
                            currentSelections.clear();
                          } else {
                            // Replace selection with new one
                            currentSelections.clear();
                            currentSelections.add(value);
                          }
                        });
                      },
                      child: RadioListTile<int>(
                        title: Text(
                          value.attValNameEn,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: value.priceValue > 0
                            ? Text(
                                value.formattedPrice,
                                style: TextStyle(color: Colors.grey[700]),
                              )
                            : null,
                        value: value.attValId,
                        groupValue: currentSelections.isNotEmpty
                            ? currentSelections.first.attValId
                            : null,
                        onChanged: null, // Disable default behavior, use InkWell instead
                      ),
                    );
                  }

                  // Use checkbox for multi-select
                  return CheckboxListTile(
                    title: Text(value.attValNameEn),
                    subtitle: value.priceValue > 0
                        ? Text(value.formattedPrice)
                        : null,
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          // Check if we can add more
                          if (currentSelections.length < widget.attribute.maxNum) {
                            currentSelections.add(value);
                          }
                        } else {
                          currentSelections.removeWhere(
                            (v) => v.attValId == value.attValId,
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // Confirm button with price summary
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate selection
                          if (widget.attribute.isMandatory &&
                              currentSelections.length < widget.attribute.minNum) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please select ${widget.attribute.minNum} option(s)',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Save selections and close
                          widget.onConfirm(currentSelections);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Separate stateful widget for combo selection sheet
class _ComboSelectionSheet extends StatefulWidget {
  final ComboCategory category;
  final List<Product> availableProducts;
  final Map<int, List<ProductAttribute>> productAttributesMap;
  final List<SelectedComboItem> initialSelections;
  final Function(List<SelectedComboItem>) onConfirm;

  const _ComboSelectionSheet({
    required this.category,
    required this.availableProducts,
    required this.productAttributesMap,
    required this.initialSelections,
    required this.onConfirm,
  });

  @override
  State<_ComboSelectionSheet> createState() => _ComboSelectionSheetState();
}

class _ComboSelectionSheetState extends State<_ComboSelectionSheet> {
  late List<SelectedComboItem> currentSelections;

  @override
  void initState() {
    super.initState();
    currentSelections = List<SelectedComboItem>.from(widget.initialSelections);
  }

  /// Calculate total combo price adjustment for current selections (including modifiers)
  double get _comboTotal {
    double total = 0.0;
    for (final selection in currentSelections) {
      total += selection.totalPrice; // Includes price adjustment + modifiers
    }
    return total;
  }

  /// Get price adjustment for a specific product
  double _getPriceAdjustment(int productId) {
    final productInfo = widget.category.productIds.firstWhere(
      (info) => info.productId == productId,
      orElse: () => ComboProductInfo(productId: productId, productPrice: '0'),
    );
    return productInfo.priceValue;
  }

  /// Show modifier selection sheet for a combo product
  void _showComboProductModifierSheet(
    Product product,
    List<ProductAttribute> attributes,
    SelectedComboItem currentSelection,
  ) {
    // If no attributes available, show a message
    if (attributes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No modifiers available for this product'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Convert ComboModifiers to a temporary selection map for the sheet
    final Map<int, List<AttributeValue>> initialModifiers = {};

    for (final attribute in attributes) {
      final selectedValues = currentSelection.modifiers
          .where((mod) => mod.attId == attribute.attId)
          .map((mod) {
            // Find the matching AttributeValue from the attribute
            return attribute.values.firstWhere(
              (val) => val.attValId == mod.attValId,
              orElse: () => AttributeValue(
                attValName: mod.attValName,
                attValId: mod.attValId,
                price: mod.price.toString(),
                defaultChoose: 0,
                attValSn: mod.attValSn,
                minNum: 0,
                maxNum: 1,
                sort: 0,
              ),
            );
          })
          .toList();

      initialModifiers[attribute.attId] = selectedValues;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ComboProductModifierSheet(
          product: product,
          attributes: attributes,
          initialModifiers: initialModifiers,
          onConfirm: (selectedModifiers) {
            setState(() {
              // Convert selected AttributeValues to ComboModifiers
              final List<ComboModifier> comboModifiers = [];
              selectedModifiers.forEach((attId, values) {
                for (final value in values) {
                  final attribute = attributes.firstWhere((attr) => attr.attId == attId);
                  comboModifiers.add(
                    ComboModifier(
                      attId: attId,
                      attName: attribute.attNameEn,
                      attValId: value.attValId,
                      attValName: value.attValNameEn,
                      attValSn: value.attValSn,
                      price: value.priceValue,
                    ),
                  );
                }
              });

              // Find and update the selection
              final index = currentSelections.indexWhere((item) => item.productId == product.productId);
              if (index != -1) {
                currentSelections[index] = currentSelections[index].copyWith(modifiers: comboModifiers);
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.typeNameEn,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.category.isMandatory
                                    ? 'Select ${widget.category.minNum}'
                                    : 'Select up to ${widget.category.maxNum}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (_comboTotal != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _comboTotal > 0 ? Colors.green[50] : Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _comboTotal > 0 ? Colors.green[300]! : Colors.red[300]!,
                                  ),
                                ),
                                child: Text(
                                  '${_comboTotal > 0 ? '+' : ''}\$${_comboTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _comboTotal > 0 ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Products list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.availableProducts.length,
                itemBuilder: (context, index) {
                  final product = widget.availableProducts[index];
                  final priceAdjustment = _getPriceAdjustment(product.productId);
                  final isSelected = currentSelections.any(
                    (item) => item.productId == product.productId,
                  );
                  // Check if product has actual modifiers available
                  final productAttributes = widget.productAttributesMap[product.productId] ?? [];
                  // Only show modifier button if there are actual attributes available
                  final hasModifiers = productAttributes.isNotEmpty;

                  // Get the current selection for this product (if selected)
                  SelectedComboItem? currentSelection;
                  if (isSelected) {
                    try {
                      currentSelection = currentSelections.firstWhere(
                        (item) => item.productId == product.productId,
                      );
                    } catch (e) {
                      currentSelection = null;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Use radio button style for single-select (maxNum = 1)
                      if (widget.category.maxNum == 1)
                        InkWell(
                          onTap: () {
                            setState(() {
                              // If already selected and not mandatory, deselect it
                              if (currentSelections.isNotEmpty &&
                                  currentSelections.first.productId == product.productId &&
                                  !widget.category.isMandatory) {
                                currentSelections.clear();
                              } else {
                                // Replace selection with new one
                                currentSelections.clear();
                                currentSelections.add(
                                  SelectedComboItem(
                                    categoryTypeNameSn: int.tryParse(widget.category.typeNameSn) ?? 0,
                                    categoryName: widget.category.typeNameEn,
                                    productId: product.productId,
                                    productSn: product.productSn,  // Added
                                    productName: product.productNameEn,
                                    priceAdjustment: priceAdjustment,
                                  ),
                                );
                              }
                            });
                          },
                          child: RadioListTile<int>(
                            title: Text(
                              product.productNameEn,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            subtitle: priceAdjustment != 0
                                ? Text(
                                    '${priceAdjustment > 0 ? '+' : ''}\$${priceAdjustment.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: priceAdjustment > 0 ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : Text(
                                    'No extra charge',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                            value: product.productId,
                            groupValue: currentSelections.isNotEmpty
                                ? currentSelections.first.productId
                                : null,
                            onChanged: null, // Disable default behavior, use InkWell instead
                          ),
                        )
                      // Use checkbox for multi-select
                      else
                        CheckboxListTile(
                          title: Text(product.productNameEn),
                          subtitle: priceAdjustment != 0
                              ? Text(
                                  '${priceAdjustment > 0 ? '+' : ''}\$${priceAdjustment.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: priceAdjustment > 0 ? Colors.green[700] : Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const Text('No extra charge'),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                // Check if we can add more
                                if (currentSelections.length < widget.category.maxNum) {
                                  currentSelections.add(
                                    SelectedComboItem(
                                      categoryTypeNameSn: int.tryParse(widget.category.typeNameSn) ?? 0,
                                      categoryName: widget.category.typeNameEn,
                                      productId: product.productId,
                                      productSn: product.productSn,  // Added
                                      productName: product.productNameEn,
                                      priceAdjustment: priceAdjustment,
                                    ),
                                  );
                                }
                              } else {
                                currentSelections.removeWhere(
                                  (item) => item.productId == product.productId,
                                );
                              }
                            });
                          },
                        ),

                      // Show modifiers button if product is selected and has modifiers
                      if (isSelected && hasModifiers && currentSelection != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show selected modifiers
                              if (currentSelection.modifiers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: currentSelection.modifiers.map((mod) {
                                      return Chip(
                                        label: Text(
                                          '${mod.attValName}${mod.price > 0 ? " (+\$${mod.price.toStringAsFixed(2)})" : ""}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.orange[100],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              // Customize button
                              TextButton.icon(
                                onPressed: () {
                                  if (currentSelection != null) {
                                    _showComboProductModifierSheet(product, productAttributes, currentSelection);
                                  }
                                },
                                icon: const Icon(Icons.tune, size: 18),
                                label: Text(currentSelection!.modifiers.isEmpty ? 'Add Modifiers' : 'Edit Modifiers'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                    ],
                  );
                },
              ),
            ),

            // Confirm button
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate selection
                          if (widget.category.isMandatory &&
                              currentSelections.length < widget.category.minNum) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please select ${widget.category.minNum} option(s)',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Save selections and close
                          widget.onConfirm(currentSelections);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Modifier selection sheet for combo products
class _ComboProductModifierSheet extends StatefulWidget {
  final Product product;
  final List<ProductAttribute> attributes;
  final Map<int, List<AttributeValue>> initialModifiers;
  final Function(Map<int, List<AttributeValue>>) onConfirm;

  const _ComboProductModifierSheet({
    required this.product,
    required this.attributes,
    required this.initialModifiers,
    required this.onConfirm,
  });

  @override
  State<_ComboProductModifierSheet> createState() => _ComboProductModifierSheetState();
}

class _ComboProductModifierSheetState extends State<_ComboProductModifierSheet> {
  late Map<int, List<AttributeValue>> currentModifiers;

  @override
  void initState() {
    super.initState();
    currentModifiers = Map<int, List<AttributeValue>>.from(widget.initialModifiers);
    // Initialize empty lists for attributes that don't have selections
    for (final attribute in widget.attributes) {
      currentModifiers.putIfAbsent(attribute.attId, () => []);
    }
  }

  /// Calculate total modifier price
  double get _modifierTotal {
    double total = 0.0;
    for (final modifierList in currentModifiers.values) {
      for (final modifier in modifierList) {
        total += modifier.priceValue;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize ${widget.product.productNameEn}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_modifierTotal > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Text(
                              '+\$${_modifierTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Attributes list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.attributes.length,
                itemBuilder: (context, index) {
                  final attribute = widget.attributes[index];
                  final selectedForThis = currentModifiers[attribute.attId] ?? [];

                  return ExpansionTile(
                    title: Text(attribute.attNameEn),
                    subtitle: Text(
                      attribute.isMandatory
                          ? 'Required - Select ${attribute.minNum}'
                          : 'Optional - Select up to ${attribute.maxNum}',
                      style: TextStyle(
                        fontSize: 12,
                        color: attribute.isMandatory ? Colors.red : Colors.grey[600],
                      ),
                    ),
                    children: attribute.values.map((value) {
                      final isSelected = selectedForThis.any((v) => v.attValId == value.attValId);

                      // Single select (radio style)
                      if (attribute.maxNum == 1) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              // If already selected and not mandatory, deselect it
                              if (selectedForThis.isNotEmpty &&
                                  selectedForThis.first.attValId == value.attValId &&
                                  !attribute.isMandatory) {
                                currentModifiers[attribute.attId] = [];
                              } else {
                                currentModifiers[attribute.attId] = [value];
                              }
                            });
                          },
                          child: RadioListTile<int>(
                            title: Text(
                              value.attValNameEn,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            subtitle: value.priceValue > 0
                                ? Text(
                                    value.formattedPrice,
                                    style: TextStyle(color: Colors.grey[700]),
                                  )
                                : null,
                            value: value.attValId,
                            groupValue: selectedForThis.isNotEmpty ? selectedForThis.first.attValId : null,
                            onChanged: null, // Disable default behavior, use InkWell instead
                          ),
                        );
                      }

                      // Multi select (checkbox style)
                      return CheckboxListTile(
                        title: Text(value.attValNameEn),
                        subtitle: value.priceValue > 0 ? Text(value.formattedPrice) : null,
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              if (selectedForThis.length < attribute.maxNum) {
                                currentModifiers[attribute.attId] = [...selectedForThis, value];
                              }
                            } else {
                              currentModifiers[attribute.attId] = selectedForThis
                                  .where((v) => v.attValId != value.attValId)
                                  .toList();
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Confirm button
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(currentModifiers);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
