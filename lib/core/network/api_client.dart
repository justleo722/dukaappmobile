import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dukaapp/core/storage/secure_storage_service.dart';
import 'package:dukaapp/core/config/api_config.dart';
import 'package:dukaapp/core/network/api_exception.dart';

class ApiClient {
  late final Dio _dio;
  final List<Function> _onUnauthorizedCallbacks = [];

  ApiClient({required SecureStorageService secureStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(secureStorage: secureStorage),
      if (ApiConfig.enableLogging) _LoggingInterceptor(),
      _ErrorInterceptor(onUnauthorized: _handleUnauthorized),
    ]);
  }

  void onUnauthorized(Function callback) {
    _onUnauthorizedCallbacks.add(callback);
  }

  void _handleUnauthorized() {
    for (final callback in _onUnauthorizedCallbacks) {
      callback();
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> upload(
    String path, {
    required FormData data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _handleBadResponse(e);
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException(message: 'Certificate verification failed.');
      case DioExceptionType.unknown:
        if (e.error is ApiException) return e.error as ApiException;
        print('[DIO UNKNOWN] error=${e.error} type=${e.error?.runtimeType} response=${e.response?.statusCode} body=${e.response?.data}');
        return NetworkException(message: 'Unable to connect. (${e.error?.runtimeType}: ${e.error})');
      default:
        if (e.error is ApiException) return e.error as ApiException;
        print('[DIO DEFAULT] error=${e.error} type=${e.error?.runtimeType}');
        return const NetworkException();
    }
  }

  ApiException _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = '';
    String? apiStatus;

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? '';
      apiStatus = data['status'] as String?;
    }

    if (statusCode == 401) {
      return UnauthorizedException(message: message.isNotEmpty ? message : 'Session expired.');
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      status: apiStatus,
      data: data,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  _AuthInterceptor({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final publicPaths = [
      ApiConfig.authSignin,
      ApiConfig.authRegister,
      ApiConfig.authResetSend,
      ApiConfig.authConstants,
    ];

    final isPublicEndpoint = publicPaths.any(
      (path) => options.path.contains(path),
    );

    if (!isPublicEndpoint) {
      final token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConfig.enableLogging) {
      print('[API REQUEST] ${options.method} ${options.uri}');
      if (options.data != null) {
        print('[API REQUEST BODY] ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConfig.enableLogging) {
      print('[API RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
      print('[API RESPONSE BODY] ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (ApiConfig.enableLogging) {
      print('[API ERROR] ${err.response?.statusCode} ${err.requestOptions.uri}');
      print('[API ERROR TYPE] ${err.type}');
      print('[API ERROR MESSAGE] ${err.message}');
      print('[API ERROR DATA] ${err.response?.data}');
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  final Function onUnauthorized;

  _ErrorInterceptor({required this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized();
    }
    handler.next(err);
  }
}
