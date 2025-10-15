import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/md5_helper.dart';
import '../models/store_credentials_model.dart';
import '../models/store_info_model.dart';

class StoreRemoteDataSource {
  final Dio dio;

  StoreRemoteDataSource({Dio? dio}) : dio = dio ?? Dio();

  /// Step 1: Locate store by ID to get API credentials
  /// GET https://mobile.jeffy.sg/api/entry/getstoreinfo/{storeId}
  Future<StoreCredentialsModel> locateStoreById(String storeId) async {
    try {
      final url = '${ApiConstants.locateStoreBaseUrl}/${ApiConstants.getStoreInfoPath}/$storeId';

      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return StoreCredentialsModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to locate store: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error while locating store: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while locating store: $e');
    }
  }

  /// Step 2: Get store information using credentials
  /// POST {apiDomain}/api/mobile/getStoreByDeviceNo with MD5 signature
  Future<StoreInfoResponse> getStoreByDeviceNo({
    required StoreCredentialsModel credentials,
    required String deviceNo,
  }) async {
    try {
      final requestBody = {'deviceNo': deviceNo};
      final bodyJson = json.encode(requestBody);

      // Generate MD5 signature
      final timestamp = Md5Helper.getCurrentTimestamp();
      final signature = Md5Helper.generateSignature(
        appKey: credentials.appKey,
        appSecret: credentials.appSecret,
        uri: ApiConstants.getStoreByDeviceNo,
        body: bodyJson,
        timestamp: timestamp,
      );

      // Prepare headers with MD5 signature
      final headers = {
        ApiConstants.headerContentType: ApiConstants.contentTypeJson,
        ApiConstants.headerTenantId: credentials.tenantId,
        ApiConstants.headerTime: timestamp.toString(),
        ApiConstants.headerSign: signature,
        ApiConstants.headerAppKey: credentials.appKey,
        ApiConstants.headerSerialNumber: credentials.deviceId,
        ApiConstants.headerSaleChannel: ApiConstants.saleChannelApp,
        ApiConstants.headerUpdateChannel: ApiConstants.updateChannelApp,
      };

      // Make API call
      final url = '${credentials.apiDomain}/${ApiConstants.getStoreByDeviceNo}';

      final response = await dio.post(
        url,
        data: bodyJson,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final storeInfoResponse = StoreInfoResponse.fromJson(response.data as Map<String, dynamic>);

        if (storeInfoResponse.isSuccess) {
          return storeInfoResponse;
        } else {
          throw Exception('API returned error: ${storeInfoResponse.desc}');
        }
      } else {
        throw Exception('Failed to get store info: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error while getting store info: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while getting store info: $e');
    }
  }
}
