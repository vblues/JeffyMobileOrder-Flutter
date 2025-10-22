import 'dart:convert';

class StoreInfoResponse {
  final String resultCode;
  final List<StoreInfo> storeInfos;
  final List<PayTypeInfo> payTypeInfo;
  final DeviceInfo? deviceInfo;
  final List<SaleTypeInfo> saleTypeInfo;
  final String? desc;

  StoreInfoResponse({
    required this.resultCode,
    required this.storeInfos,
    required this.payTypeInfo,
    this.deviceInfo,
    required this.saleTypeInfo,
    this.desc,
  });

  factory StoreInfoResponse.fromJson(Map<String, dynamic> json) {
    return StoreInfoResponse(
      resultCode: json['result_code'].toString(),
      storeInfos: (json['storeInfos'] as List<dynamic>?)
              ?.map((e) => StoreInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payTypeInfo: (json['payTypeInfo'] as List<dynamic>?)
              ?.map((e) => PayTypeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deviceInfo: json['DeviceInfo'] != null
          ? DeviceInfo.fromJson(json['DeviceInfo'] as Map<String, dynamic>)
          : null,
      saleTypeInfo: (json['saleTypeInfo'] as List<dynamic>?)
              ?.map((e) => SaleTypeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      desc: json['desc'] as String?,
    );
  }

  bool get isSuccess => resultCode == '200';
}

class StoreInfo {
  final int storeId;
  final String storeSn;
  final String storeNote; // JSON string
  final String? payPlatform;
  final String storeName; // JSON string {"cn":"", "en":""}
  final String? storeAddr;
  final String? street;
  final String? contactPhone;
  final String? longitude;
  final String? latitude;
  final String? workTime; // JSON string

  StoreInfo({
    required this.storeId,
    required this.storeSn,
    required this.storeNote,
    this.payPlatform,
    required this.storeName,
    this.storeAddr,
    this.street,
    this.contactPhone,
    this.longitude,
    this.latitude,
    this.workTime,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {

    // Handle both int and string for store_id
    int parsedStoreId;
    final storeIdValue = json['store_id'];
    if (storeIdValue is int) {
      parsedStoreId = storeIdValue;
    } else if (storeIdValue is String) {
      try {
        parsedStoreId = int.parse(storeIdValue);
      } catch (e) {
        throw Exception('Invalid store_id value: $storeIdValue');
      }
    } else if (storeIdValue == null) {
      throw Exception('store_id is required but was null');
    } else {
      throw Exception('Invalid store_id type: ${storeIdValue.runtimeType}');
    }


    return StoreInfo(
      storeId: parsedStoreId,
      storeSn: json['store_sn'] as String? ?? '',
      storeNote: json['store_note'] as String? ?? '{}',
      payPlatform: json['pay_platform'] as String?,
      storeName: json['store_name'] as String? ?? '{}',
      storeAddr: json['store_addr'] as String?,
      street: json['street'] as String?,
      contactPhone: json['contact_phone'] as String?,
      longitude: json['longitude'] as String?,
      latitude: json['latitude'] as String?,
      workTime: json['work_time'] as String?,
    );
  }

  /// Parse store_note JSON string
  Map<String, dynamic> get storeNoteData {
    try {
      return json.decode(storeNote) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Parse store_name JSON string and get English name
  String get storeNameEn {
    try {
      final nameMap = json.decode(storeName) as Map<String, dynamic>;
      return nameMap['en'] as String? ?? nameMap['cn'] as String? ?? '';
    } catch (e) {
      return storeName;
    }
  }

  /// Get brand color from store_note
  String get brandColor {
    try {
      final note = storeNoteData;
      return note['LandingPage']?['TopBarColorCode'] as String? ?? '#996600';
    } catch (e) {
      return '#996600';
    }
  }

  /// Get logo URL from store_note
  String? get logoUrl {
    try {
      final note = storeNoteData;
      return note['Images']?['Logo'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get secure HTTPS logo URL (convert HTTP to HTTPS)
  String? get secureLogoUrl {
    final url = logoUrl;
    if (url == null) return null;
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  /// Get landing page image URL from store_note
  String? get landingPageUrl {
    try {
      final note = storeNoteData;
      return note['Images']?['LandingPage'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get secure HTTPS landing page URL (convert HTTP to HTTPS)
  String? get secureLandingPageUrl {
    final url = landingPageUrl;
    if (url == null) return null;
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  /// Get pager info from store_note
  PagerInfo get pagerInfo {
    try {
      final note = storeNoteData;
      final pagerData = note['Pager'] as Map<String, dynamic>?;
      if (pagerData != null) {
        return PagerInfo.fromJson(pagerData);
      }
      return PagerInfo(enabled: false);
    } catch (e) {
      return PagerInfo(enabled: false);
    }
  }

  /// Get sales type configuration from store_note
  SalesTypeConfig get salesTypeConfig {
    try {
      final note = storeNoteData;
      final salesTypeData = note['SalesType'] as Map<String, dynamic>?;
      if (salesTypeData != null) {
        final config = SalesTypeConfig.fromJson(salesTypeData);
        return config;
      }
      return SalesTypeConfig.defaultConfig();
    } catch (e, stackTrace) {
      return SalesTypeConfig.defaultConfig();
    }
  }
}

class PayTypeInfo {
  final int id;
  final String payName;
  final String payCode;

  PayTypeInfo({
    required this.id,
    required this.payName,
    required this.payCode,
  });

  factory PayTypeInfo.fromJson(Map<String, dynamic> json) {
    return PayTypeInfo(
      id: json['id'] as int,
      payName: json['pay_name'] as String? ?? '',
      payCode: json['pay_code'] as String? ?? '',
    );
  }
}

class DeviceInfo {
  final String? deviceName;
  final String? ip;
  final int? storeId;

  DeviceInfo({
    this.deviceName,
    this.ip,
    this.storeId,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceName: json['device_name'] as String?,
      ip: json['ip'] as String?,
      storeId: json['store_id'] as int?,
    );
  }
}

class SaleTypeInfo {
  final int id;
  final String saleTypeName;
  final String saleTypeCode;

  SaleTypeInfo({
    required this.id,
    required this.saleTypeName,
    required this.saleTypeCode,
  });

  factory SaleTypeInfo.fromJson(Map<String, dynamic> json) {
    return SaleTypeInfo(
      id: json['id'] as int,
      saleTypeName: json['sale_type_name'] as String? ?? '',
      saleTypeCode: json['sale_type_code'].toString(),
    );
  }
}

/// Pager information for dine-in orders
class PagerInfo {
  final bool enabled;
  final String? message;
  final String? imageUrl;

  PagerInfo({
    required this.enabled,
    this.message,
    this.imageUrl,
  });

  factory PagerInfo.fromJson(Map<String, dynamic> json) {
    return PagerInfo(
      enabled: json['Enabled'] as bool? ?? false,
      message: json['Message'] as String?,
      imageUrl: json['Image'] as String?,
    );
  }

  /// Get secure HTTPS image URL (convert HTTP to HTTPS)
  String? get secureImageUrl {
    final url = imageUrl;
    if (url == null) return null;
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }
}

/// Sales type configuration from store_note
class SalesTypeConfig {
  final SalesTypeDetail? dineIn;
  final SalesTypeDetail? takeaway;
  final SalesTypeDetail? pickUp;

  SalesTypeConfig({
    this.dineIn,
    this.takeaway,
    this.pickUp,
  });

  factory SalesTypeConfig.fromJson(Map<String, dynamic> json) {

    SalesTypeDetail? dineIn;
    SalesTypeDetail? takeaway;
    SalesTypeDetail? pickUp;

    try {
      if (json['DineIn'] != null) {
        dineIn = SalesTypeDetail.fromJson(json['DineIn'] as Map<String, dynamic>);
      }
    } catch (e) {
      rethrow;
    }

    try {
      if (json['Takeaway'] != null) {
        takeaway = SalesTypeDetail.fromJson(json['Takeaway'] as Map<String, dynamic>);
      }
    } catch (e) {
      rethrow;
    }

    try {
      if (json['PickUp'] != null) {
        pickUp = SalesTypeDetail.fromJson(json['PickUp'] as Map<String, dynamic>);
      }
    } catch (e) {
      rethrow;
    }

    return SalesTypeConfig(
      dineIn: dineIn,
      takeaway: takeaway,
      pickUp: pickUp,
    );
  }

  /// Default configuration (fallback values)
  factory SalesTypeConfig.defaultConfig() {
    return SalesTypeConfig(
      dineIn: SalesTypeDetail(id: 1, successMsg: '', failMsg: ''),
      takeaway: SalesTypeDetail(id: 2, successMsg: '', failMsg: ''),
      pickUp: SalesTypeDetail(id: 5, successMsg: '', failMsg: ''),
    );
  }
}

/// Sales type detail (id and messages)
class SalesTypeDetail {
  final int id;
  final String successMsg;
  final String failMsg;

  SalesTypeDetail({
    required this.id,
    required this.successMsg,
    required this.failMsg,
  });

  factory SalesTypeDetail.fromJson(Map<String, dynamic> json) {
    // Diagnostic logging

    // Handle both int and string for id
    int parsedId;
    final idValue = json['id'];
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue is String) {
      try {
        parsedId = int.parse(idValue);
      } catch (e) {
        rethrow;
      }
    } else {
      throw Exception('Invalid id value: $idValue');
    }


    return SalesTypeDetail(
      id: parsedId,
      successMsg: json['SuccessMsg'] as String? ?? '',
      failMsg: json['FailMsg'] as String? ?? '',
    );
  }
}
