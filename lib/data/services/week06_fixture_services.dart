import '../models/rating_request.dart';
import '../models/common_response.dart';
import '../models/sign_up_models.dart';

import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/tmdb_movie_dto.dart';
import 'sign_up_service.dart';
import 'rating_api_service.dart';
import 'fixture_movie_service.dart';

/// Explicit debug/test fixtures. The app factories guard these with kDebugMode.
class FixtureSignUpService extends SignUpService {
  FixtureSignUpService({
    this.fail = false,
    this.delay = const Duration(milliseconds: 1200),
  }) : super(Dio());
  bool fail;
  final Duration delay;
  final List<String> nicknameRequests = [];
  final List<String> emailRequests = [];
  Future<bool> _check(
    String value,
    String duplicate,
    List<String> requests,
  ) async {
    requests.add(value);
    await Future<void>.delayed(delay);
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v6/members'),
        type: DioExceptionType.connectionError,
      );
    }
    return value != duplicate;
  }

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async => CommonResponse(
    isSuccess: true,
    code: 'COMMON201',
    message: 'fixture signup',
    result: SignUpResult(
      memberId: 9001,
      email: request.email,
      nickname: request.nickname,
    ),
  );
  @override
  Future<bool> checkNickname(String nickname) =>
      _check(nickname.trim(), '수현', nicknameRequests);
  @override
  Future<bool> checkEmail(String email) =>
      _check(email.trim(), 'noco@umc.com', emailRequests);
}

class FixtureRatingApiService extends RatingApiService {
  FixtureRatingApiService(
    this.mode, {
    this.delay = const Duration(milliseconds: 1200),
  }) : super(Dio());
  final String mode;
  final Duration delay;
  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {}
  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {}
  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {}
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    await Future<void>.delayed(delay);
    if (mode == 'error') {
      throw DioException(
        requestOptions: RequestOptions(path: '/v6/members/$memberId/ratings'),
        type: DioExceptionType.connectionError,
      );
    }
    if (mode == 'empty') return const [];
    return [
      RatingDto(
        ratingId: 3,
        movieId: 13,
        score: 3,
        comment: null,
        createdAt: DateTime.utc(2026, 11, 8),
        updatedAt: DateTime.utc(2026, 11, 8),
      ),
      RatingDto(
        ratingId: 2,
        movieId: 680,
        score: 4,
        comment: '다시 봐도 좋다',
        createdAt: DateTime.utc(2026, 11, 8),
        updatedAt: DateTime.utc(2026, 11, 8),
      ),
      RatingDto(
        ratingId: 1,
        movieId: 550,
        score: 5,
        comment: '최고의 영화!',
        createdAt: DateTime.utc(2026, 11, 8),
        updatedAt: DateTime.utc(2026, 11, 8),
      ),
    ];
  }
}

class Week06FixtureMovieService extends FixtureMovieService {
  Week06FixtureMovieService(this.fixtureMode) : super('posters');
  final String fixtureMode;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    if (fixtureMode == 'tmdb-error') {
      throw DioException(
        requestOptions: RequestOptions(path: '/movie/$movieId'),
        type: DioExceptionType.connectionError,
      );
    }
    return TmdbMovieDto(
      id: movieId,
      title: {13: '포레스트 검프', 680: '펄프 픽션', 550: '파이트 클럽'}[movieId] ?? '검증 영화',
      releaseDate: '1994-01-01',
    );
  }
}
