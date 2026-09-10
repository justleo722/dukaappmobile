class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? status;
  final dynamic data;

  const ApiException({
    this.statusCode,
    required this.message,
    this.status,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  String get friendlyMessage {
    switch (statusCode) {
      case 400:
        return message.isNotEmpty ? message : 'Invalid request. Please check your input.';
      case 401:
        return 'Your session has expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 408:
        return 'Connection timed out. Please check your internet connection.';
      case 422:
        return message.isNotEmpty ? message : 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'A server error occurred. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable. Please try again later.';
      case 503:
        return 'Service is currently unavailable. Please try again later.';
      default:
        if (message.isNotEmpty) return message;
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

class NetworkException extends ApiException {
  const NetworkException({String message = 'Unable to connect to DukaApp. Please check your internet connection.'})
      : super(message: message, statusCode: null);
}

class TimeoutException extends ApiException {
  const TimeoutException({String message = 'Connection timed out. Please check your internet connection.'})
      : super(message: message, statusCode: 408);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({String message = 'Your session has expired. Please login again.'})
      : super(message: message, statusCode: 401);
}
