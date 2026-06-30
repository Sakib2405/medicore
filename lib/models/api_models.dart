// A standardized success response from your API
class ApiResponse<T> {
  final T data;
  final bool success;
  final String? message;

  ApiResponse({
    required this.data,
    this.success = true,
    this.message,
  });
}

// A standardized error response from your API
class ApiError {
  final String message;
  final String? code; // e.g., 'auth_failed'
  final int? statusCode;

  ApiError({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String,
      code: json['code'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }
}
