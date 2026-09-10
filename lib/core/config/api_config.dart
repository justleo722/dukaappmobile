class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://dukaapp.net';
  static const String appApiBase = '/api/v1/app';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static bool enableLogging = true;

  // Auth endpoints
  static const String authSignin = '$appApiBase/auth/signin';
  static const String authRegister = '$appApiBase/auth/register';
  static const String authAddShop = '$appApiBase/auth/addshop';
  static String authSwitchShop(String shopId) =>
      '$appApiBase/auth/switchshop/$shopId';
  static const String authResetSend = '$appApiBase/auth/reset/send';
  static const String authSignout = '$appApiBase/auth/signout';
  static const String authConstants = '$appApiBase/auth/constants';

  // Generic data endpoints
  static String getData(String key) => '$appApiBase/get/getdata/$key';
  static String getReport(String key) => '$appApiBase/get/getreport/$key';
  static const String dashboard = '$appApiBase/get/dashboard';
  static String postData(String key) => '$appApiBase/post/postdata/$key';
}
