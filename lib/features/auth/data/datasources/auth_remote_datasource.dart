import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/network/api_response.dart';
import 'package:dukaapp/core/network/api_exception.dart';
import 'package:dukaapp/core/config/api_config.dart';
import 'package:dukaapp/features/auth/data/models/auth_models.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Map<String, String> _buildLoginPayload({
    required String identifier,
    required String password,
  }) {
    final payload = <String, String>{
      'password': password,
    };

    if (_isEmail(identifier)) {
      payload['email'] = identifier;
    } else if (_isPhone(identifier)) {
      payload['phone'] = identifier;
    } else {
      payload['username'] = identifier;
    }

    return payload;
  }

  Map<String, String> _buildResetPayload({required String identifier}) {
    final payload = <String, String>{};

    if (_isEmail(identifier)) {
      payload['email'] = identifier;
    } else if (_isPhone(identifier)) {
      payload['phone'] = identifier;
    } else {
      payload['username'] = identifier;
    }

    return payload;
  }

  bool _isEmail(String value) => value.contains('@') && value.contains('.');
  bool _isPhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AuthDatasource] $message');
    }
  }

  void _logResponse(String method, dynamic response) {
    if (kDebugMode) {
      try {
        debugPrint('[AuthDatasource] $method response: ${response.statusCode}');
        debugPrint('[AuthDatasource] $method body: ${response.data}');
      } catch (_) {}
    }
  }

  void _logError(String method, dynamic error) {
    if (kDebugMode) {
      debugPrint('[AuthDatasource] $method ERROR: $error');
      if (error is ApiException) {
        debugPrint('[AuthDatasource] ERROR status: ${error.statusCode}');
        debugPrint('[AuthDatasource] ERROR message: ${error.message}');
        debugPrint('[AuthDatasource] ERROR data: ${error.data}');
      }
    }
  }

  Future<Response> _postForm(String path, Map<String, String> data) async {
    final response = await _apiClient.post(
      path,
      data: data,
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
    return response;
  }

  Future<ApiResponse<AuthResult>> login({
    required String identifier,
    required String password,
  }) async {
    final payload = _buildLoginPayload(identifier: identifier, password: password);
    _log('Login request: $payload');

    try {
      final response = await _postForm(ApiConfig.authSignin, payload);
      _logResponse('login', response);
      return _parseAuthResponse(response);
    } on ApiException catch (e) {
      _logError('login', e);
      rethrow;
    } catch (e) {
      _logError('login', e);
      rethrow;
    }
  }

  Future<ApiResponse<AuthResult>> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String country,
    required String iso,
    required String region,
    required String shopName,
    required String shopType,
    required dynamic lobId,
    bool agreeToTerms = true,
  }) async {
    final payload = {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'country': country,
      'iso': iso,
      'region': region,
      'shop_name': shopName,
      'shop_type': shopType,
      'lob_id': lobId.toString(),
      'terms': '1',
      'agree_terms': '1',
      'terms_accepted': '1',
      'accept_terms': '1',
      'terms_conditions': '1',
      't_and_c': '1',
    };
    _log('Register request: $payload');

    try {
      final response = await _postForm(ApiConfig.authRegister, payload);
      _logResponse('register', response);
      return _parseAuthResponse(response);
    } on ApiException catch (e) {
      _logError('register', e);
      rethrow;
    } catch (e) {
      _logError('register', e);
      rethrow;
    }
  }

  ApiResponse<AuthResult> _parseAuthResponse(dynamic response) {
    final body = response.data;

    _log('Parsing response body: $body (${body.runtimeType})');

    if (body == null) {
      throw const ApiException(message: 'Empty response from server.');
    }

    Map<String, dynamic> jsonBody;
    if (body is String) {
      try {
        jsonBody = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException(
          message: 'Invalid response format from server.',
          statusCode: response.statusCode,
        );
      }
    } else if (body is Map<String, dynamic>) {
      jsonBody = body;
    } else {
      throw ApiException(
        message: 'Unexpected response type: ${body.runtimeType}',
        statusCode: response.statusCode,
      );
    }

    final rawStatus = jsonBody['status'];
    final status = rawStatus?.toString();
    final message = jsonBody['message']?.toString();
    final isSuccess = rawStatus == true || status == 'success' || status == 'true';

    _log('Parsed status: $status, message: $message, isSuccess: $isSuccess');

    if (!isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: message ?? 'Request failed. Please try again.',
        status: status,
        data: jsonBody,
      );
    }

    final data = jsonBody['data'] ?? jsonBody['result'];
    final token = _extractToken(jsonBody, data);
    final user = _extractUser(jsonBody, data);
    final shop = _extractShop(jsonBody, data);
    final shops = _extractShops(jsonBody, data);

    _log('Extracted token: ${token != null ? 'yes' : 'no'}');
    _log('Extracted user: ${user != null ? 'yes' : 'no'}');
    _log('Extracted shop: ${shop != null ? 'yes' : 'no'}');

    return ApiResponse.success(
      AuthResult(
        success: true,
        message: message,
        token: token,
        user: user,
        shop: shop,
        shops: shops,
      ),
      message: message,
    );
  }

  String? _extractToken(Map<String, dynamic> body, dynamic data) {
    String? _str(dynamic v) => v?.toString();
    if (data is Map<String, dynamic>) {
      final t = _str(data['token']) ?? _str(data['access_token']) ?? _str(data['jwt']);
      if (t != null) return t;
    }
    return _str(body['token']) ?? _str(body['access_token']) ?? _str(body['jwt']);
  }

  User? _extractUser(Map<String, dynamic> body, dynamic data) {
    dynamic userJson;
    if (data is Map<String, dynamic>) {
      userJson = data['user'] ?? data['session'];
    }
    userJson ??= body['user'] ?? body['session'];

    if (userJson is Map<String, dynamic>) {
      return User.fromJson(userJson);
    }
    return null;
  }

  Shop? _extractShop(Map<String, dynamic> body, dynamic data) {
    dynamic shopJson;
    if (data is Map<String, dynamic>) {
      shopJson = data['shop'] ?? data['active_shop'];
    }
    shopJson ??= body['shop'] ?? body['active_shop'];

    if (shopJson is Map<String, dynamic>) {
      return Shop.fromJson(shopJson);
    }
    return null;
  }

  List<Shop>? _extractShops(Map<String, dynamic> body, dynamic data) {
    dynamic shopsRaw;
    if (data is Map<String, dynamic>) {
      shopsRaw = data['shops'];
    }
    shopsRaw ??= body['shops'];

    if (shopsRaw is List) {
      return shopsRaw
          .whereType<Map<String, dynamic>>()
          .map(Shop.fromJson)
          .toList();
    }
    return null;
  }

  Future<ApiResponse<void>> sendPasswordReset({
    required String identifier,
  }) async {
    final payload = _buildResetPayload(identifier: identifier);
    _log('Reset password request: $payload');

    try {
      final response = await _postForm(ApiConfig.authResetSend, payload);
      _logResponse('reset', response);

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        return ApiResponse.error('Invalid response from server.');
      }

      final rawStatus = body['status'];
      final status = rawStatus?.toString();
      final message = body['message']?.toString();
      final isSuccess = rawStatus == true || status == 'success' || status == 'true';

      if (!isSuccess) {
        throw ApiException(
          statusCode: response.statusCode,
          message: message ?? 'Failed to send reset code.',
          status: status,
        );
      }

      return ApiResponse<void>.success(null as dynamic, message: message);
    } on ApiException catch (e) {
      _logError('reset', e);
      rethrow;
    } catch (e) {
      _logError('reset', e);
      rethrow;
    }
  }

  Future<ApiResponse<void>> signOut() async {
    try {
      await _apiClient.get(ApiConfig.authSignout);
    } catch (_) {}
    return ApiResponse<void>.success(null as dynamic);
  }

  Future<ApiResponse<AuthConstants>> getConstants() async {
    try {
      final response = await _apiClient.get(ApiConfig.authConstants);
      _logResponse('constants', response);

      final body = response.data;
      Map<String, dynamic> jsonBody;
      if (body is String) {
        jsonBody = jsonDecode(body) as Map<String, dynamic>;
      } else if (body is Map<String, dynamic>) {
        jsonBody = body;
      } else {
        return ApiResponse.error('Invalid response from server.');
      }

      final data = jsonBody['data'] ?? jsonBody;
      final constants = AuthConstants.fromJson({'data': data});
      return ApiResponse.success(constants);
    } catch (e) {
      _logError('constants', e);
      return ApiResponse.error('Failed to load constants: $e');
    }
  }

  Future<ApiResponse<AuthResult>> addShop({
    required String shopName,
    required String shopType,
    required dynamic lobId,
  }) async {
    final response = await _postForm(ApiConfig.authAddShop, {
      'shop_name': shopName,
      'shop_type': shopType,
      'lob_id': lobId.toString(),
    });
    _logResponse('addShop', response);
    return _parseAuthResponse(response);
  }

  Future<ApiResponse<void>> switchShop(String shopId) async {
    final response = await _apiClient.post(
      ApiConfig.authSwitchShop(shopId),
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final rawStatus = body['status'];
      final status = rawStatus?.toString();
      final message = body['message']?.toString();
      if (rawStatus != true && status != 'success' && status != 'true') {
        throw ApiException(
          message: message ?? 'Failed to switch shop.',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse<void>.success(null as dynamic);
  }

  Future<ApiResponse<AuthResult>> validateSession() async {
    final response = await _apiClient.get(
      ApiConfig.getData('session_user'),
    );
    _logResponse('validateSession', response);
    return _parseAuthResponse(response);
  }
}
