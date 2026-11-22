import 'package:dio/dio.dart';

import '../models/api_failure.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import 'session_api_service.dart' show result;

/// v7: public member listing, JWT protected writes without memberId.
class RatingApiService {
  RatingApiService(this.publicClient, this.authClient);
  final Dio publicClient, authClient;
  Future<RatingDto> create(CreateRatingRequest request) async =>
      RatingDto.fromJson(
        result(
          await authClient.post('/v7/ratings', data: request.toJson()),
          status: 201,
        ),
      );
  Future<RatingDto> update(RatingDto rating, int score, String? comment) async {
    validateServerScore(score.toDouble());
    return RatingDto.fromJson(
      result(
        await authClient.patch(
          '/v7/ratings/${rating.ratingId}',
          data: {'score': score, 'comment': normalizedComment(comment)},
        ),
      ),
    );
  }

  Future<void> delete(int id) async {
    final response = await authClient.delete('/v7/ratings/$id');
    final body = response.data;
    if (response.statusCode != 200 ||
        body is! Map ||
        body['isSuccess'] != true ||
        body['result'] != null) {
      throw const ApiFailure('삭제 응답을 확인하지 못했습니다.');
    }
  }

  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await publicClient.get<List<dynamic>>(
      '/v7/members/$memberId/ratings',
    );
    return response.data!
        .map((e) => RatingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
