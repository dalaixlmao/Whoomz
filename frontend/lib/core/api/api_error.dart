import 'package:dio/dio.dart';

class ApiError implements Exception {
  final int? statusCode;
  final String message;

  const ApiError({this.statusCode, required this.message});

  factory ApiError.fromDio(DioException e) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] as String? : null;
    return ApiError(
      statusCode: e.response?.statusCode,
      message: detail ?? e.message ?? 'Unknown error',
    );
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}
