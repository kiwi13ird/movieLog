import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/tmdb_config.dart';

Dio createTmdbClient() {
  final token = TmdbConfig.accessToken;
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Authorization': 'Bearer $token', 'accept': 'application/json'},
    ),
  );
  if (kDebugMode) dio.interceptors.add(TmdbLoggingInterceptor());
  return dio;
}

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
    debugPrint('[TMDB Header] Authorization: Bearer ***');
    debugPrint('[TMDB Query] ${options.queryParameters}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[TMDB 응답] ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[TMDB 응답 Body] ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Never print the exception/request headers: they may contain credentials.
    debugPrint(
      '[TMDB 오류] ${err.requestOptions.uri} status=${err.response?.statusCode} type=${err.type.name}',
    );
    debugPrint('[TMDB 오류 내용] 요청 실패 (${err.type.name})');
    handler.next(err);
  }
}
