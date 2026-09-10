class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final String? status;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.status,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? fromData, {
    int? httpStatusCode,
  }) {
    final status = json['status'] as String?;
    final message = json['message'] as String?;
    final rawData = json['data'] ?? json['result'];

    final isSuccess =
        status == 'success' || status == 'true' || (httpStatusCode != null && httpStatusCode >= 200 && httpStatusCode < 300);

    return ApiResponse(
      success: isSuccess,
      message: message,
      data: fromData != null ? fromData(rawData) : rawData as T?,
      statusCode: httpStatusCode,
      status: status,
    );
  }

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
