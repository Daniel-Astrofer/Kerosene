class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
  final String? timestamp;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.timestamp,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
      if (errorCode != null) 'errorCode': errorCode,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}
