import 'package:dio/dio.dart';

import 'dart:io';

/// Read-only Swagger validation. Does not create members or touch anyone's ratings.
Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  try {
    final response = await dio.get<Map<String, dynamic>>('/docs/v6-json');
    final paths = response.data!['paths'] as Map<String, dynamic>;
    final expected = {
      '/v6/members': {'post': '201'},
      '/v6/members/nickname/{nickname}': {'get': '200'},
      '/v6/members/email/{email}': {'get': '200'},
      '/v6/members/{memberId}/ratings': {'get': '200', 'post': '201'},
      '/v6/members/{memberId}/ratings/{ratingId}': {
        'patch': '200',
        'delete': '204',
      },
    };
    for (final path in expected.entries) {
      for (final method in path.value.entries) {
        final operation = (paths[path.key] as Map)[method.key] as Map;
        if (!(operation['responses'] as Map).containsKey(method.value)) {
          throw StateError('Contract changed');
        }
        stdout.writeln(
          'PASS: ${method.key.toUpperCase()} ${path.key} → ${method.value}',
        );
      }
    }
    stdout.writeln(
      'Read-only schema validation. No live signup/rating writes were executed.',
    );
  } catch (_) {
    stderr.writeln('FAIL: v6 schema/network verification failed.');
    exitCode = 1;
  } finally {
    dio.close(force: true);
  }
}
