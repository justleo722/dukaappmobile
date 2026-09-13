class ApiConfig {
  ApiConfig._();

  // ── Base URL ────────────────────────────────────────────────────────────────
  // Local dev  → http://192.168.0.107  (LAMPP on this machine, subfolder /dukaapp)
  // Production → https://dukaapp.net   (root, no subfolder)
  static const String baseUrl = 'http://localhost';
  static const String _subFolder = '/dukaapp';
  // static const String baseUrl = 'https://dukaapp.com';
  // static const String _subFolder = ''; // production: root

  static const String appApiBase = '$baseUrl$_subFolder/api/v1/app';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static bool enableLogging = true; // set false before production

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
