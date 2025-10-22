import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../datasources/store_remote_datasource.dart';
import '../models/store_credentials_model.dart';
import '../models/store_info_model.dart';

class StoreRepository {
  final StoreRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  StoreRepository({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  /// Locate store and fetch full store information
  /// This is the complete flow: locateStoreById → getStoreByDeviceNo
  Future<StoreInfoResponse> fetchStoreData(String storeId) async {
    try {

      // Step 1: Locate store to get API credentials
      final credentials = await remoteDataSource.locateStoreById(storeId);

      // Cache credentials
      await _saveCredentials(credentials);

      // Step 2: Get store info using credentials
      final storeInfo = await remoteDataSource.getStoreByDeviceNo(
        credentials: credentials,
        deviceNo: credentials.deviceId,
      );

      // Cache store info
      await _saveStoreInfo(storeInfo);

      // Cache store ID
      if (storeInfo.storeInfos.isNotEmpty) {
        await sharedPreferences.setString(
          StorageKeys.storeId,
          storeInfo.storeInfos.first.storeId.toString(),
        );
      }

      return storeInfo;
    } catch (e) {
      rethrow;
    }
  }

  /// Get cached credentials
  StoreCredentialsModel? getCachedCredentials() {
    try {
      final credentialsJson = sharedPreferences.getString(StorageKeys.storeCredentials);
      if (credentialsJson != null) {
        return StoreCredentialsModel.fromJsonString(credentialsJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get cached store ID
  String? getCachedStoreId() {
    return sharedPreferences.getString(StorageKeys.storeId);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await sharedPreferences.remove(StorageKeys.storeCredentials);
    await sharedPreferences.remove(StorageKeys.storeInfo);
    await sharedPreferences.remove(StorageKeys.storeId);
  }

  // Private helper methods

  Future<void> _saveCredentials(StoreCredentialsModel credentials) async {
    await sharedPreferences.setString(
      StorageKeys.storeCredentials,
      credentials.toJsonString(),
    );
  }

  Future<void> _saveStoreInfo(StoreInfoResponse storeInfo) async {
    // Save the full store info as JSON including payment methods from store_note
    if (storeInfo.storeInfos.isNotEmpty) {
      final storeData = storeInfo.storeInfos.first;

      // Parse store_note to extract PayType
      List<Map<String, dynamic>> payTypeInfo = [];
      try {
        if (storeData.storeNote.isNotEmpty) {
          final storeNoteData = json.decode(storeData.storeNote) as Map<String, dynamic>;
          final payTypeList = storeNoteData['PayType'] as List<dynamic>?;
          if (payTypeList != null) {
            payTypeInfo = payTypeList.map((item) {
              final payTypeItem = item as Map<String, dynamic>;
              return {
                'id': payTypeItem['id'],
                'pay_code': payTypeItem['pay_code'],
                // Add a friendly name based on ID
                'pay_name': payTypeItem['id'] == 23 ? 'Pay at Counter' :
                           payTypeItem['id'] == 60 ? 'Credit Card' : 'Payment',
              };
            }).toList();
          }
        }
      } catch (e) {
      }

      final jsonData = {
        'store_id': storeData.storeId, // Fixed: use 'store_id' instead of 'id'
        'store_name': storeData.storeName, // Raw JSON string
        'store_sn': storeData.storeSn,
        'store_note': storeData.storeNote,
        'brand_color': storeData.brandColor,
        'logo_url': storeData.logoUrl,
        'street': storeData.street,
        'contact_phone': storeData.contactPhone,
        // Include payment methods parsed from store_note
        'payTypeInfo': payTypeInfo,
      };
      await sharedPreferences.setString(
        StorageKeys.storeInfo,
        json.encode(jsonData),
      );
    }
  }
}
