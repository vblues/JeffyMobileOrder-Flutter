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
    // Helper function to safely convert any value to String
    String _toString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return StoreCredentialsModel(
      appKey: _toString(json['appKey']),
      appSecret: _toString(json['appSecret']),
      tenantId: _toString(json['tenantID']),
      deviceId: _toString(json['deviceID']),
      apiDomain: _toString(json['apiDomain']),
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
