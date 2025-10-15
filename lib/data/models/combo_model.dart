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
      activityComboId: json['activity_combo_id'] as int? ?? 0,
      activitySn: json['activity_sn'] as String? ?? '',
      activityName: json['activity_name'] as String? ?? '{}',
      activityPic: json['activity_pic'] as String? ?? '',
      discountSn: json['discount_sn'] as String? ?? '',
      discountType: json['discount_type'] as int? ?? 0,
      discountNum: json['discount_num'] as String? ?? '0.00',
      startTime: json['start_time'] as int? ?? 0,
      endTime: json['end_time'] as int? ?? 0,
      actCycleDaytime: json['act_cycle_daytime'] as String? ?? '',
      categories: (json['cdata'] as List<dynamic>?)
              ?.map((e) => ComboCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
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
      minNum: json['min_num'] as int? ?? 0,
      maxNum: json['max_num'] as int? ?? 1,
      typeNameSn: json['type_name_sn'] as String? ?? '',
      isChoice: json['is_choice'] as int? ?? 0,
      sort: json['sort'] as int? ?? 0,
      productIds: (json['product_id'] as List<dynamic>?)
              ?.map((e) => ComboProductInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultIds: (json['default_id'] as List<dynamic>?)
              ?.map((e) => e as int)
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
      productId: json['product_id'] as int? ?? 0,
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
  final List<dynamic> modifiers; // Product modifiers if any

  SelectedComboItem({
    required this.categoryTypeNameSn,
    required this.categoryName,
    required this.productId,
    required this.productName,
    required this.priceAdjustment,
    this.modifiers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryTypeNameSn': categoryTypeNameSn,
      'categoryName': categoryName,
      'productId': productId,
      'productName': productName,
      'priceAdjustment': priceAdjustment,
      'modifiers': modifiers,
    };
  }

  factory SelectedComboItem.fromJson(Map<String, dynamic> json) {
    return SelectedComboItem(
      categoryTypeNameSn: json['categoryTypeNameSn'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
      modifiers: json['modifiers'] as List<dynamic>? ?? [],
    );
  }
}
