import 'dart:io';

import 'package:dio/dio.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

/// Explicit opt-in, read-only live verification; never prints credentials.
Future<void> main() async {
  final client = createMovieLogClient();
  Dio? tmdb;
  try {
    final checks = MemberCheckService(client);
    final nickname = await checks.checkNickname('week06_sample');
    final email = await checks.checkEmail('week06.sample@example.com');
    stdout.writeln(
      'PASS: v5 nickname/email GET raw available booleans ($nickname / $email)',
    );
    final ratings = await RatingApiService(client).fetchMyRatings(1);
    stdout.writeln(
      'PASS: memberId 1 ratings=${ratings.length}, null comments=${ratings.where((r) => r.comment == null).length}',
    );
    final env = File('.env');
    final match = env.existsSync()
        ? RegExp(
            r'^TMDB_ACCESS_TOKEN\s*=\s*(.*)$',
            multiLine: true,
          ).firstMatch(env.readAsStringSync())
        : null;
    var token = match?.group(1)?.trim() ?? '';
    if (token.length >= 2 &&
        ((token.startsWith('"') && token.endsWith('"')) ||
            (token.startsWith("'") && token.endsWith("'")))) {
      token = token.substring(1, token.length - 1);
    }
    if (token.isEmpty) {
      stdout.writeln(
        'SKIP: TMDB token is not configured; details were not verified live.',
      );
      return;
    }
    tmdb = Dio(
      BaseOptions(
        baseUrl: 'https://api.themoviedb.org/3',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final movies = TmdbMovieService(tmdb);
    for (final id in ratings.map((r) => r.movieId).toSet()) {
      final movie = await movies.findMovieById(id);
      if (movie == null) {
        stdout.writeln('TMDB id=$id: 404, rating retained with placeholder');
      } else {
        if (movie.id != id) throw StateError('Movie identity mismatch');
        stdout.writeln(
          'PASS: TMDB movieId=$id, title parsed, poster=${movie.posterPath != null}',
        );
      }
    }
  } on DioException catch (error) {
    stderr.writeln(
      'FAIL: status=${error.response?.statusCode}, type=${error.type.name}',
    );
    exitCode = 1;
  } catch (_) {
    stderr.writeln('FAIL: response/configuration parsing failed.');
    exitCode = 1;
  } finally {
    client.close(force: true);
    tmdb?.close(force: true);
  }
}
