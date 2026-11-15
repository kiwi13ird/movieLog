import 'package:dio/dio.dart';

/// v5 workbook API is independent of the TMDB token/client.
Dio createMovieLogClient() => Dio(
  BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'accept': 'application/json'},
  ),
);
