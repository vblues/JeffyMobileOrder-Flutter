import 'dart:convert';

/// Model for product attributes (modifiers)
/// Based on API response from getProductAtt
class ProductAttributeResponse {
  final int resultCode;
  final List<ProductAttributeGroup> attributes;
  final String description;

  ProductAttributeResponse({
    required this.resultCode,
    required this.attributes,
    required this.description,
  });

  factory ProductAttributeResponse.fromJson(Map<String, dynamic> json) {
    return ProductAttributeResponse(
      resultCode: json['result_code'] as int,
      attributes: (json['atts'] as List<dynamic>?)
              ?.map((item) => ProductAttributeGroup.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      description: json['desc'] as String? ?? '',
    );
  }
}

/// Group of attributes for a specific product
class ProductAttributeGroup {
  final int productId;
  final int productType;
  final List<ProductAttribute> attributes;

  ProductAttributeGroup({
    required this.productId,
    required this.productType,
    required this.attributes,
  });

  factory ProductAttributeGroup.fromJson(Map<String, dynamic> json) {
    return ProductAttributeGroup(
      productId: json['product_id'] as int,
      productType: json['product_type'] as int? ?? 1,
      attributes: (json['atts'] as List<dynamic>?)
              ?.map((item) => ProductAttribute.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Individual attribute (e.g., "Drink Modifier", "Size", "Temperature")
class ProductAttribute {
  final int attId;
  final String attrSn;
  final String attName; // JSON string: {"en": "Name", "cn": "Name"}
  final int multiSelect; // 0 = single select, 1 = multi select
  final int minNum; // Minimum selections required
  final int maxNum; // Maximum selections allowed
  final int sort;
  final List<AttributeValue> values;

  ProductAttribute({
    required this.attId,
    required this.attrSn,
    required this.attName,
    required this.multiSelect,
    required this.minNum,
    required this.maxNum,
    required this.sort,
    required this.values,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      attId: json['att_id'] as int,
      attrSn: json['attr_sn'] as String? ?? '',
      attName: json['att_name'] as String? ?? '{"en":"","cn":""}',
      multiSelect: json['multi_select'] as int? ?? 0,
      minNum: json['min_num'] as int? ?? 0,
      maxNum: json['max_num'] as int? ?? 1,
      sort: json['sort'] as int? ?? 0,
      values: (json['att_val_info'] as List<dynamic>?)
              ?.map((item) => AttributeValue.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get attribute name in English
  String get attNameEn {
    try {
      final nameJson = jsonDecode(attName);
      return nameJson['en'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Get attribute name in Chinese
  String get attNameCn {
    try {
      final nameJson = jsonDecode(attName);
      return nameJson['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Check if this is a mandatory selection (min == max and > 0)
  bool get isMandatory => minNum == maxNum && minNum > 0;

  /// Check if this is a multi-select attribute
  bool get isMultiSelect => multiSelect == 1;
}

/// Individual attribute value (e.g., "Hot", "Cold", "Large", "Small")
class AttributeValue {
  final String attValName; // JSON string: {"en": "Value", "cn": "Value"}
  final int attValId;
  final String price; // String format, e.g., "0.50"
  final int defaultChoose; // 0 or 1
  final String attValSn;
  final int minNum;
  final int maxNum;
  final int sort;

  AttributeValue({
    required this.attValName,
    required this.attValId,
    required this.price,
    required this.defaultChoose,
    required this.attValSn,
    required this.minNum,
    required this.maxNum,
    required this.sort,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      attValName: json['att_val_name'] as String? ?? '{"en":"","cn":""}',
      attValId: json['att_val_id'] as int,
      price: json['price'] as String? ?? '0.00',
      defaultChoose: json['default_choose'] as int? ?? 0,
      attValSn: json['att_val_sn'] as String? ?? '',
      minNum: json['min_num'] as int? ?? 0,
      maxNum: json['max_num'] as int? ?? 1,
      sort: json['sort'] as int? ?? 0,
    );
  }

  /// Get attribute value name in English
  String get attValNameEn {
    try {
      final nameJson = jsonDecode(attValName);
      return nameJson['en'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Get attribute value name in Chinese
  String get attValNameCn {
    try {
      final nameJson = jsonDecode(attValName);
      return nameJson['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Get price as double
  double get priceValue {
    try {
      return double.parse(price);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get formatted price string
  String get formattedPrice {
    return '\$${priceValue.toStringAsFixed(2)}';
  }

  /// Check if this value is selected by default
  bool get isDefault => defaultChoose == 1;
}

/// Model for selected modifier in cart
class SelectedModifier {
  final int attId;
  final String attName;
  final int attValId;
  final String attValName;
  final String attValSn;
  final double price;

  SelectedModifier({
    required this.attId,
    required this.attName,
    required this.attValId,
    required this.attValName,
    required this.attValSn,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'att_id': attId,
      'att_name': attName,
      'att_val_id': attValId,
      'att_val_name': attValName,
      'att_val_sn': attValSn,
      'price': price,
    };
  }

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      attId: json['att_id'] as int,
      attName: json['att_name'] as String,
      attValId: json['att_val_id'] as int,
      attValName: json['att_val_name'] as String,
      attValSn: json['att_val_sn'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}
