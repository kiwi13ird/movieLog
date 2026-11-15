import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

class RatingApiService {
  RatingApiService(this.dio);
  final Dio dio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await dio.get<List<dynamic>>(
      '/v5/members/$memberId/ratings',
    );
    return response.data!
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  switch (error.response?.statusCode) {
    case 400:
      return 'memberId 형식을 다시 확인해 주세요.';
    case 404:
      return '존재하지 않는 회원입니다.';
    default:
      return '평점을 불러오지 못했습니다. 연결을 확인하고 다시 시도해 주세요.';
  }
}
