import 'dart:convert';

/// Response from getActivityComboWithPrice API
class ComboActivityResponse {
  final int resultCode;
  final List<ComboActivity> activities;
  final String desc;

  ComboActivityResponse({
    required this.resultCode,
    required this.activities,
    required this.desc,
  });

  factory ComboActivityResponse.fromJson(Map<String, dynamic> json) {
    return ComboActivityResponse(
      resultCode: json['result_code'] as int? ?? 0,
      activities: (json['data'] as List<dynamic>?)
              ?.map((e) => ComboActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      desc: json['desc'] as String? ?? '',
    );
  }
}

/// Individual combo/activity configuration
class ComboActivity {
  final int activityComboId;
  final String activitySn;
  final String activityName; // JSON string {"cn":"...", "en":"..."}
  final String activityPic;
  final String discountSn;
  final int discountType;
  final String discountNum;
  final int startTime;
  final int endTime;
  final String actCycleDaytime;
  final List<ComboCategory> categories;

  ComboActivity({
    required this.activityComboId,
    required this.activitySn,
    required this.activityName,
    required this.activityPic,
    required this.discountSn,
    required this.discountType,
    required this.discountNum,
    required this.startTime,
    required this.endTime,
    required this.actCycleDaytime,
    required this.categories,
  });

  factory ComboActivity.fromJson(Map<String, dynamic> json) {
    return ComboActivity(
      activityComboId: _parseIntWithDefault(json['activity_combo_id'], 0),
      activitySn: json['activity_sn'] as String? ?? '',
      activityName: json['activity_name'] as String? ?? '{}',
      activityPic: json['activity_pic'] as String? ?? '',
      discountSn: json['discount_sn'] as String? ?? '',
      discountType: _parseIntWithDefault(json['discount_type'], 0),
      discountNum: json['discount_num'] as String? ?? '0.00',
      startTime: _parseIntWithDefault(json['start_time'], 0),
      endTime: _parseIntWithDefault(json['end_time'], 0),
      actCycleDaytime: json['act_cycle_daytime'] as String? ?? '',
      categories: (json['cdata'] as List<dynamic>?)
              ?.map((e) => ComboCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Helper to parse int from dynamic value with default (handles both int and String)
  static int _parseIntWithDefault(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Get activity name in English
  String get activityNameEn {
    try {
      final nameJson = jsonDecode(activityName);
      return nameJson['en'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Get activity name in Chinese
  String get activityNameCn {
    try {
      final nameJson = jsonDecode(activityName);
      return nameJson['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Check if this activity is currently active based on time
  bool get isActive {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= startTime && now <= endTime;
  }
}

/// Category within a combo (e.g., "Main", "Drinks", "Sides")
class ComboCategory {
  final String typeName; // JSON string {"cn":"...", "en":"..."}
  final int minNum;
  final int maxNum;
  final String typeNameSn;
  final int isChoice;
  final int sort;
  final List<ComboProductInfo> productIds;
  final List<int> defaultIds;

  ComboCategory({
    required this.typeName,
    required this.minNum,
    required this.maxNum,
    required this.typeNameSn,
    required this.isChoice,
    required this.sort,
    required this.productIds,
    required this.defaultIds,
  });

  factory ComboCategory.fromJson(Map<String, dynamic> json) {
    return ComboCategory(
      typeName: json['type_name'] as String? ?? '{}',
      minNum: ComboActivity._parseIntWithDefault(json['min_num'], 0),
      maxNum: ComboActivity._parseIntWithDefault(json['max_num'], 1),
      typeNameSn: json['type_name_sn'] as String? ?? '',
      isChoice: ComboActivity._parseIntWithDefault(json['is_choice'], 0),
      sort: ComboActivity._parseIntWithDefault(json['sort'], 0),
      productIds: (json['product_id'] as List<dynamic>?)
              ?.map((e) => ComboProductInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultIds: (json['default_id'] as List<dynamic>?)
              ?.map((e) => ComboActivity._parseIntWithDefault(e, 0))
              .toList() ??
          [],
    );
  }

  /// Get category name in English
  String get typeNameEn {
    try {
      final nameJson = jsonDecode(typeName);
      return nameJson['en'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Get category name in Chinese
  String get typeNameCn {
    try {
      final nameJson = jsonDecode(typeName);
      return nameJson['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Check if this category is mandatory
  bool get isMandatory => minNum > 0 && minNum == maxNum;

  /// Check if multiple selections allowed
  bool get allowsMultipleSelection => maxNum > 1;

  /// Check if a product ID is in this category
  bool containsProductId(int productId) {
    return productIds.any((p) => p.productId == productId);
  }

  /// Get price adjustment for a specific product
  double getPriceAdjustment(int productId) {
    final productInfo = productIds.firstWhere(
      (p) => p.productId == productId,
      orElse: () => ComboProductInfo(productId: 0, productPrice: '0.00'),
    );
    return productInfo.priceValue;
  }
}

/// Product information within a combo category
class ComboProductInfo {
  final int productId;
  final String productPrice;

  ComboProductInfo({
    required this.productId,
    required this.productPrice,
  });

  factory ComboProductInfo.fromJson(Map<String, dynamic> json) {
    return ComboProductInfo(
      productId: ComboActivity._parseIntWithDefault(json['product_id'], 0),
      productPrice: json['product_price'] as String? ?? '0.00',
    );
  }

  /// Get price as double
  double get priceValue {
    try {
      return double.parse(productPrice);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get formatted price string
  String get formattedPrice {
    final price = priceValue;
    if (price >= 0) {
      return '+\$${price.toStringAsFixed(2)}';
    } else {
      return '-\$${(-price).toStringAsFixed(2)}';
    }
  }
}

/// Selected combo item for cart
class SelectedComboItem {
  final int categoryTypeNameSn;
  final String categoryName;
  final int productId;
  final String productName;
  final double priceAdjustment;
  final List<ComboModifier> modifiers; // Product modifiers if any

  SelectedComboItem({
    required this.categoryTypeNameSn,
    required this.categoryName,
    required this.productId,
    required this.productName,
    required this.priceAdjustment,
    this.modifiers = const [],
  });

  /// Get total modifier price for this combo item
  double get modifierTotal {
    return modifiers.fold(0.0, (sum, mod) => sum + mod.price);
  }

  /// Get total price including base price adjustment and modifiers
  double get totalPrice => priceAdjustment + modifierTotal;

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

  factory SelectedComboItem.fromJson(Map<String, dynamic> json) {
    return SelectedComboItem(
      categoryTypeNameSn: ComboActivity._parseIntWithDefault(json['categoryTypeNameSn'], 0),
      categoryName: json['categoryName'] as String? ?? '',
      productId: ComboActivity._parseIntWithDefault(json['productId'], 0),
      productName: json['productName'] as String? ?? '',
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
      modifiers: (json['modifiers'] as List<dynamic>?)
          ?.map((m) => ComboModifier.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Create a copy with updated modifiers
  SelectedComboItem copyWith({
    List<ComboModifier>? modifiers,
  }) {
    return SelectedComboItem(
      categoryTypeNameSn: categoryTypeNameSn,
      categoryName: categoryName,
      productId: productId,
      productName: productName,
      priceAdjustment: priceAdjustment,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}

/// Modifier selected for a combo product
class ComboModifier {
  final int attId;
  final String attName;
  final int attValId;
  final String attValName;
  final String attValSn;
  final double price;

  ComboModifier({
    required this.attId,
    required this.attName,
    required this.attValId,
    required this.attValName,
    required this.attValSn,
    required this.price,
  });

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

  factory ComboModifier.fromJson(Map<String, dynamic> json) {
    return ComboModifier(
      attId: ComboActivity._parseIntWithDefault(json['attId'], 0),
      attName: json['attName'] as String,
      attValId: ComboActivity._parseIntWithDefault(json['attValId'], 0),
      attValName: json['attValName'] as String,
      attValSn: json['attValSn'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}
