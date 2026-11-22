import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.storage, this.version);
  final TokenStorage storage;
  final int Function() version;
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.removeWhere(
      (key, _) => key.toLowerCase() == 'authorization',
    );
    final uri = options.uri;
    final protected =
        uri.scheme == 'https' &&
        uri.host == 'workbook.devnoco.com' &&
        uri.port == 443 &&
        (uri.path == '/v7/members/me' ||
            uri.path == '/v7/ratings' ||
            RegExp(r'^/v7/ratings/[0-9]+$').hasMatch(uri.path));
    if (protected) {
      final current = version();
      try {
        final token = await storage.readAccessToken();
        if (current != version()) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
          return;
        }
        options.extra['sessionVersion'] = current;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        handler.reject(
          DioException(requestOptions: options, error: '인증 저장소를 읽지 못했습니다.'),
        );
        return;
      }
    }
    handler.next(options);
  }
}
