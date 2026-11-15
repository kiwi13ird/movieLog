import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/week07_fixture_adapter.dart';

class FixedAdapter implements HttpClientAdapter {
  FixedAdapter(this.status, this.body);
  final int status;
  final String body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test('signup model preserves password; scores are integers and empty PATCH comment explicitly clears', () {
    final request = CreateMemberRequest(
      email: ' a@example.com ',
      password: ' Pass123! ',
      nickname: ' 이름 ',
    );
    expect(request.toJson(), {
      'email': 'a@example.com',
      'password': ' Pass123! ',
      'nickname': '이름',
    });
    expect(
      const CreateRatingRequest(movieId: 550, score: 5, comment: ' ').toJson(),
      {'movieId': 550, 'score': 5},
    );
    for (final score in [0.0, 0.5, 1.5, 5.5, double.nan, double.infinity]) {
      expect(() => validateServerScore(score), throwsArgumentError);
    }
    expect(() => normalizedComment('a' * 501), throwsArgumentError);
    expect(
      CommonResponse<Object?>.fromJson({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': '성공',
        'result': null,
      }, (_) => throw StateError('must not parse null')).result,
      isNull,
    );
  });
  test('actual v6 services parse signup once, direct ratings and 201/200/204 without forwarding a token', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'));
    final adapter = Week07FixtureAdapter('success', delay: Duration.zero);
    dio.httpClientAdapter = adapter;
    final member = await SignUpService(dio).signUp(
      const CreateMemberRequest(
        email: 'a@example.com',
        password: 'Valid123!',
        nickname: '검증닉네임',
      ),
    );
    expect(member.result!.memberId, 9001);
    final service = RatingApiService(dio);
    await service.createRating(
      memberId: 9001,
      request: const CreateRatingRequest(movieId: 550, score: 5, comment: '최고'),
    );
    final records = await service.fetchMyRatings(9001);
    expect(records.single.movieId, 550);
    await service.updateRating(
      memberId: 9001,
      ratingId: records.single.ratingId,
      score: 3,
      comment: null,
    );
    final patch = adapter.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.data, {'score': 3, 'comment': null});
    await service.deleteRating(
      memberId: 9001,
      ratingId: records.single.ratingId,
    );
    expect(await service.fetchMyRatings(9001), isEmpty);
    expect(
      adapter.requests.every(
        (r) =>
            r.path.startsWith('/v6/') &&
            !r.headers.containsKey('Authorization'),
      ),
      isTrue,
    );
    expect(adapter.requests.first.data['password'], '***');
    dio.close();
  });
  test('create accepts number/null result but rejects success false; DELETE never parses a body', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'));
    final service = RatingApiService(dio);
    for (final body in [
      '{"isSuccess":true,"code":"COMMON201","message":"ok","result":null}',
      '{"isSuccess":true,"code":"COMMON201","message":"ok","result":8}',
    ]) {
      dio.httpClientAdapter = FixedAdapter(201, body);
      await service.createRating(
        memberId: 9001,
        request: const CreateRatingRequest(movieId: 550, score: 4),
      );
    }
    dio.httpClientAdapter = FixedAdapter(
      201,
      '{"isSuccess":false,"code":"COMMON409","message":"중복","result":null}',
    );
    await expectLater(
      service.createRating(
        memberId: 9001,
        request: const CreateRatingRequest(movieId: 550, score: 4),
      ),
      throwsA(isA<ApiFailure>()),
    );
    dio.httpClientAdapter = FixedAdapter(204, '');
    await service.deleteRating(memberId: 9001, ratingId: 8);
    dio.close();
  });
  test('400/403/404/409 errors preserve server message and only stale ownership errors request refresh', () {
    for (final status in [400, 403, 404, 409]) {
      final failure = ApiFailure.from(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: status,
            data: {
              'isSuccess': false,
              'code': 'COMMON$status',
              'message': '서버 안내 $status',
              'result': null,
            },
          ),
        ),
      );
      expect(failure.message, '서버 안내 $status');
      expect(failure.shouldRefresh, status == 403 || status == 404);
    }
  });
}
