class ApiConstants {
  // Base URLs
  static const String locateStoreBaseUrl = 'https://mobile.jeffy.sg/api/entry';

  // Endpoints
  static const String getStoreInfoPath = 'getstoreinfo';
  static const String getStoreByDeviceNo = 'api/mobile/getStoreByDeviceNo';
  static const String getMenu = 'api/mobile/getMenu';
  static const String getProductByStore = 'api/mobile/getProductByStore';
  static const String getProductAtt = 'api/mobile/getProductAtt';
  static const String getActivityComboWithPrice = 'api/mobile/getActivityComboWithPrice';
  static const String getStoreComboProduct = 'api/mobile/getStoreComboProduct';
  static const String userLogin = 'api/user/userLogin';
  static const String userRegister = 'api/user/userRegister';
  static const String getOtp = 'api/user/getOTP';
  static const String sendMobileOrder = 'api/mobile/sendMobileOrder';
  static const String paymentUpdate = 'api/mobile/paymentUpdate';
  static const String getTnc = 'api/mobile/getTNC';
  static const String getPrivacyPolicy = 'api/mobile/getPrivacyPolicy';
  static const String getCancelRefunds = 'api/mobile/getCancelRefunds';

  // Headers
  static const String headerContentType = 'Content-Type';
  static const String headerTenantId = 'Tenant-Id';
  static const String headerTime = 'time';
  static const String headerSign = 'sign';
  static const String headerAppKey = 'appkey';
  static const String headerSerialNumber = 'Serial-Number';
  static const String headerSaleChannel = 'Sale-Channel';
  static const String headerUpdateChannel = 'Update-Channel';

  // Header Values
  static const String contentTypeJson = 'application/json';
  static const String saleChannelApp = 'APP';
  static const String updateChannelApp = 'APP';

  // Result Codes
  static const String resultCodeSuccess = '200';
  static const String resultCodeSpecial = '7103';
}
