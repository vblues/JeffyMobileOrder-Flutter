import 'dart:convert';
import 'product_model.dart';
import 'product_attribute_model.dart';
import 'combo_model.dart';

/// Cart item containing product, modifiers, combos, and quantity
class CartItem {
  final String id; // Unique ID for this cart item
  final Product product;
  final int quantity;
  final List<CartModifier> modifiers;
  final List<CartComboItem> comboItems;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.modifiers = const [],
    this.comboItems = const [],
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Calculate base price (product price + modifiers)
  double get basePrice {
    double price = product.priceValue;
    for (final modifier in modifiers) {
      price += modifier.price;
    }
    return price;
  }

  /// Calculate combo items total price
  double get comboPrice {
    double price = 0.0;
    for (final comboItem in comboItems) {
      price += comboItem.totalPrice;
    }
    return price;
  }

  /// Calculate price per item (base + combos)
  double get pricePerItem => basePrice + comboPrice;

  /// Calculate total price (price per item * quantity)
  double get totalPrice => pricePerItem * quantity;

  /// Check if this item has modifiers or combos
  bool get hasCustomizations => modifiers.isNotEmpty || comboItems.isNotEmpty;

  /// Create a copy with updated quantity
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<CartModifier>? modifiers,
    List<CartComboItem>? comboItems,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
      comboItems: comboItems ?? this.comboItems,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'comboItems': comboItems.map((c) => c.toJson()).toList(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((m) => CartModifier.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      comboItems: (json['comboItems'] as List<dynamic>?)
              ?.map((c) => CartComboItem.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, product: ${product.productNameEn}, quantity: $quantity, total: \$${totalPrice.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modifier selected for a cart item
class CartModifier {
  final int attId;
  final String attName;
  final int attValId;
  final String attValName;
  final String attValSn;
  final double price;

  CartModifier({
    required this.attId,
    required this.attName,
    required this.attValId,
    required this.attValName,
    required this.attValSn,
    required this.price,
  });

  /// Create from AttributeValue
  factory CartModifier.fromAttributeValue(
      int attId, String attName, AttributeValue value) {
    return CartModifier(
      attId: attId,
      attName: attName,
      attValId: value.attValId,
      attValName: value.attValNameEn,
      attValSn: value.attValSn,
      price: value.priceValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attId': attId,
      'attName': attName,
      'attValId': attValId,
      'attValName': attValName,
      'attValSn': attValSn,
      'price': price,
    };
  }

  factory CartModifier.fromJson(Map<String, dynamic> json) {
    return CartModifier(
      attId: json['attId'] as int,
      attName: json['attName'] as String,
      attValId: json['attValId'] as int,
      attValName: json['attValName'] as String,
      attValSn: json['attValSn'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return '$attValName${price > 0 ? " (+\$${price.toStringAsFixed(2)})" : ""}';
  }
}

/// Combo item in cart
class CartComboItem {
  final int categoryTypeNameSn;
  final String categoryName;
  final int productId;
  final String productName;
  final double priceAdjustment;
  final List<CartModifier> modifiers;

  CartComboItem({
    required this.categoryTypeNameSn,
    required this.categoryName,
    required this.productId,
    required this.productName,
    required this.priceAdjustment,
    this.modifiers = const [],
  });

  /// Get total modifier price
  double get modifierTotal {
    return modifiers.fold(0.0, (sum, mod) => sum + mod.price);
  }

  /// Get total price (price adjustment + modifiers)
  double get totalPrice => priceAdjustment + modifierTotal;

  /// Create from SelectedComboItem
  factory CartComboItem.fromSelectedComboItem(SelectedComboItem item) {
    return CartComboItem(
      categoryTypeNameSn: item.categoryTypeNameSn,
      categoryName: item.categoryName,
      productId: item.productId,
      productName: item.productName,
      priceAdjustment: item.priceAdjustment,
      modifiers: item.modifiers
          .map((m) => CartModifier(
                attId: m.attId,
                attName: m.attName,
                attValId: m.attValId,
                attValName: m.attValName,
                attValSn: m.attValSn,
                price: m.price,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryTypeNameSn': categoryTypeNameSn,
      'categoryName': categoryName,
      'productId': productId,
      'productName': productName,
      'priceAdjustment': priceAdjustment,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
    };
  }

  factory CartComboItem.fromJson(Map<String, dynamic> json) {
    return CartComboItem(
      categoryTypeNameSn: json['categoryTypeNameSn'] as int,
      categoryName: json['categoryName'] as String,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      priceAdjustment: (json['priceAdjustment'] as num).toDouble(),
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((m) => CartModifier.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    final modifiersStr = modifiers.isNotEmpty ? ' with ${modifiers.length} modifier(s)' : '';
    return '$productName${priceAdjustment != 0 ? " (${priceAdjustment > 0 ? '+' : ''}\$${priceAdjustment.toStringAsFixed(2)})" : ""}$modifiersStr';
  }
}

/// Cart summary information
class CartSummary {
  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final double serviceCharge;
  final double tax;
  final double total;

  CartSummary({
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotal,
    this.serviceCharge = 0.0,
    this.tax = 0.0,
  }) : total = subtotal + serviceCharge + tax;

  Map<String, dynamic> toJson() {
    return {
      'itemCount': itemCount,
      'totalQuantity': totalQuantity,
      'subtotal': subtotal,
      'serviceCharge': serviceCharge,
      'tax': tax,
      'total': total,
    };
  }
}
