import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = options.path.endsWith('/ratings')
        ? [
            {
              'ratingId': 12,
              'movieId': 550,
              'score': 5,
              'comment': null,
              'createdAt': '2026-11-08T12:00:00Z',
              'updatedAt': '2026-11-08T12:00:00Z',
            },
          ]
        : {'available': false};
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('v5 services use raw bodies, encoded path segments and no TMDB authorization', () async {
    final dio = createMovieLogClient();
    final adapter = RecordingAdapter();
    dio.httpClientAdapter = adapter;
    final service = MemberCheckService(dio);
    expect(await service.checkNickname(' 수현 '), isFalse);
    expect(adapter.requests.last.uri.pathSegments.last, '수현');
    expect(await service.checkEmail(' new+tag@example.com '), isFalse);
    expect(adapter.requests.last.uri.pathSegments.last, 'new+tag@example.com');
    final ratings = await RatingApiService(dio).fetchMyRatings(1);
    expect(ratings.single.ratingId, 12);
    expect(ratings.single.comment, isNull);
    expect(ratings.single.updatedAt.isUtc, isTrue);
    expect(
      adapter.requests.last.uri.toString(),
      'https://workbook.devnoco.com/v5/members/1/ratings',
    );
    expect(
      adapter.requests.every(
        (r) => r.method == 'GET' && !r.headers.containsKey('Authorization'),
      ),
      isTrue,
    );
    dio.close();
  });
  test(
    'rating numeric fields/date parsing and TMDB detail genres are supported',
    () {
      final rating = RatingDto.fromJson({
        'ratingId': 3.0,
        'movieId': 13,
        'score': 3,
        'comment': null,
        'createdAt': '2026-11-08T12:00:00Z',
        'updatedAt': '2026-11-08T12:00:00Z',
      });
      expect(rating.ratingId, 3);
      final movie = TmdbMovieDto.fromJson({
        'id': 550,
        'title': '영화',
        'genres': [
          {'id': 18, 'name': '드라마'},
        ],
      });
      expect(movie.genreIds, [18]);
    },
  );
}
