import 'dart:convert';

class ProductResponse {
  final int resultCode;
  final List<Product> products;
  final String? desc;

  ProductResponse({
    required this.resultCode,
    required this.products,
    this.desc,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      resultCode: json['result_code'] as int? ?? 0,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      desc: json['desc'] as String?,
    );
  }

  bool get isSuccess => resultCode == 200;
}

class Product {
  final int status;
  final int cid;
  final int cateId;
  final String? productPic;
  final int productId;
  final String productName; // JSON string {"cn":"...", "en":"..."}
  final String? note;
  final String productSn;
  final int isTakeOut;
  final String price;
  final int sortSn;
  final String startTime;
  final String endTime;
  final String ingredientName; // JSON string {"cn":"...", "en":"..."}
  final int ingredientsId;
  final int effectiveStartTime;
  final int effectiveEndTime;
  final int hasModifiers;

  Product({
    required this.status,
    required this.cid,
    required this.cateId,
    this.productPic,
    required this.productId,
    required this.productName,
    this.note,
    required this.productSn,
    required this.isTakeOut,
    required this.price,
    required this.sortSn,
    required this.startTime,
    required this.endTime,
    required this.ingredientName,
    required this.ingredientsId,
    required this.effectiveStartTime,
    required this.effectiveEndTime,
    required this.hasModifiers,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      status: json['status'] as int? ?? 0,
      cid: json['cid'] as int? ?? 0,
      cateId: json['cate_id'] as int? ?? 0,
      productPic: json['product_pic'] as String?,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? '{}',
      note: json['note'] as String?,
      productSn: json['product_sn'] as String? ?? '',
      isTakeOut: json['is_take_out'] as int? ?? 0,
      price: json['price'] as String? ?? '0.00',
      sortSn: json['sort_sn'] as int? ?? 0,
      startTime: json['start_time'] as String? ?? '00:00:00',
      endTime: json['end_time'] as String? ?? '23:59:59',
      ingredientName: json['ingredient_name'] as String? ?? '{}',
      ingredientsId: json['ingredients_id'] as int? ?? 0,
      effectiveStartTime: json['effective_start_time'] as int? ?? 0,
      effectiveEndTime: json['effective_end_time'] as int? ?? 0,
      hasModifiers: json['hasModifiers'] as int? ?? 0,
    );
  }

  /// Parse product_name JSON string and get English name
  String get productNameEn {
    try {
      final nameMap = json.decode(productName) as Map<String, dynamic>;
      return nameMap['en'] as String? ?? nameMap['cn'] as String? ?? '';
    } catch (e) {
      return productName;
    }
  }

  /// Parse product_name JSON string and get Chinese name
  String get productNameCn {
    try {
      final nameMap = json.decode(productName) as Map<String, dynamic>;
      return nameMap['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Parse ingredient_name JSON string and get English name
  String get ingredientNameEn {
    try {
      final nameMap = json.decode(ingredientName) as Map<String, dynamic>;
      return nameMap['en'] as String? ?? nameMap['cn'] as String? ?? '';
    } catch (e) {
      return ingredientName;
    }
  }

  /// Parse ingredient_name JSON string and get Chinese name
  String get ingredientNameCn {
    try {
      final nameMap = json.decode(ingredientName) as Map<String, dynamic>;
      return nameMap['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Check if product is active
  bool get isActive => status == 1;

  /// Check if product is available for takeout
  bool get isTakeOutAvailable => isTakeOut == 1;

  /// Check if product has modifiers
  bool get hasModifiersAvailable => hasModifiers == 1;

  /// Get price as double
  double get priceValue {
    try {
      return double.parse(price);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if product is available at current time
  bool isAvailableNow() {
    final now = DateTime.now();
    final currentTimestamp = now.millisecondsSinceEpoch ~/ 1000;

    // Check effective date range
    if (currentTimestamp < effectiveStartTime ||
        currentTimestamp > effectiveEndTime) {
      return false;
    }

    // Check time of day availability
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start == null || end == null) return true;

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes >= startMinutes) {
      // Normal case: e.g., 07:00 - 22:00
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Crosses midnight: e.g., 22:00 - 02:00
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// Parse time string "HH:MM:SS" to TimeOfDay
  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Get formatted price string
  String get formattedPrice {
    return '\$${priceValue.toStringAsFixed(2)}';
  }

  /// Get secure HTTPS product image URL (convert HTTP to HTTPS)
  String? get secureProductPic {
    if (productPic == null) return null;
    if (productPic!.startsWith('http://')) {
      return productPic!.replaceFirst('http://', 'https://');
    }
    return productPic;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'cid': cid,
      'cate_id': cateId,
      'product_pic': productPic,
      'product_id': productId,
      'product_name': productName,
      'note': note,
      'product_sn': productSn,
      'is_take_out': isTakeOut,
      'price': price,
      'sort_sn': sortSn,
      'start_time': startTime,
      'end_time': endTime,
      'ingredient_name': ingredientName,
      'ingredients_id': ingredientsId,
      'effective_start_time': effectiveStartTime,
      'effective_end_time': effectiveEndTime,
      'hasModifiers': hasModifiers,
    };
  }

  @override
  String toString() {
    return 'Product(id: $productId, name: $productNameEn, price: $formattedPrice)';
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});
}
