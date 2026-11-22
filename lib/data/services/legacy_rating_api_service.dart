import 'package:dio/dio.dart';

import '../models/api_failure.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

class LegacyRatingApiService {
  LegacyRatingApiService(this.dio);
  final Dio dio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await dio.get<List<dynamic>>(
      '/v6/members/$memberId/ratings',
    );
    return response.data!
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _success(Response<Map<String, dynamic>> response, int status) {
    if (response.statusCode != status) {
      throw const ApiFailure('저장 결과를 확인하지 못했습니다. 다시 요청하기 전에 목록을 확인해 주세요.');
    }
    final body = CommonResponse<Object?>.fromJson(
      response.data!,
      (value) => value,
    );
    if (!body.isSuccess) throw ApiFailure(body.message, code: body.code);
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    _success(
      await dio.post<Map<String, dynamic>>(
        '/v6/members/$memberId/ratings',
        data: request.toJson(),
      ),
      201,
    );
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    _success(
      await dio.patch<Map<String, dynamic>>(
        '/v6/members/$memberId/ratings/$ratingId',
        data: {'score': score, 'comment': normalizedComment(comment)},
      ),
      200,
    );
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await dio.delete<void>(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw const ApiFailure('삭제 결과를 확인하지 못했습니다. 목록을 다시 확인해 주세요.');
    }
  }
}

String writeMyRatingsErrorMessage(DioException error) => ApiFailure.from(
  error,
  fallback: '평점을 불러오지 못했습니다. 연결을 확인하고 다시 시도해 주세요.',
).message;
