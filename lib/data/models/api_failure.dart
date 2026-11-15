import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status, this.code});
  final String message;
  final int? status;
  final String? code;
  bool get shouldRefresh =>
      code == 'COMMON403' ||
      code == 'COMMON404' ||
      status == 403 ||
      status == 404;
  factory ApiFailure.from(
    Object error, {
    String fallback = '요청에 실패했습니다. 연결을 확인하고 다시 시도해 주세요.',
  }) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      final code = data is Map ? data['code'] : null;
      return ApiFailure(
        message is String ? message : fallback,
        status: error.response?.statusCode,
        code: code is String ? code : null,
      );
    }
    return ApiFailure(fallback);
  }
  @override
  String toString() => message;
}
