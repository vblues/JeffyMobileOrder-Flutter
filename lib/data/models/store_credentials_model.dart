import 'dart:convert';

/// Model for API credentials returned from locate store endpoint
class StoreCredentialsModel {
  final String appKey;
  final String appSecret;
  final String tenantId;
  final String deviceId;
  final String apiDomain;

  StoreCredentialsModel({
    required this.appKey,
    required this.appSecret,
    required this.tenantId,
    required this.deviceId,
    required this.apiDomain,
  });

  factory StoreCredentialsModel.fromJson(Map<String, dynamic> json) {
    return StoreCredentialsModel(
      appKey: json['appKey'] as String? ?? '',
      appSecret: json['appSecret'] as String? ?? '',
      tenantId: json['tenantID'] as String? ?? '',
      deviceId: json['deviceID'] as String? ?? '',
      apiDomain: json['apiDomain'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appKey': appKey,
      'appSecret': appSecret,
      'tenantID': tenantId,
      'deviceID': deviceId,
      'apiDomain': apiDomain,
    };
  }

  String toJsonString() => json.encode(toJson());

  factory StoreCredentialsModel.fromJsonString(String jsonString) {
    return StoreCredentialsModel.fromJson(json.decode(jsonString));
  }

  @override
  String toString() {
    return 'StoreCredentialsModel(appKey: $appKey, tenantId: $tenantId, deviceId: $deviceId, apiDomain: $apiDomain)';
  }
}
