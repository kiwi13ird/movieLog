import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/legacy_rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/week06_fixture_services.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class ControlledChecks extends SignUpService {
  ControlledChecks() : super(Dio());
  final nicknames = <Completer<bool>>[];
  final emails = <Completer<bool>>[];
  @override
  Future<bool> checkNickname(String nickname) {
    final c = Completer<bool>();
    nicknames.add(c);
    return c.future;
  }

  @override
  Future<bool> checkEmail(String email) {
    final c = Completer<bool>();
    emails.add(c);
    return c.future;
  }
}

class StubRatings extends LegacyRatingApiService {
  StubRatings() : super(Dio());
  final ids = <int>[];
  late Future<List<RatingDto>> Function() fetch;
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    ids.add(memberId);
    return fetch();
  }
}

class StubMovies extends TmdbMovieService {
  StubMovies() : super(Dio());
  final calls = <int>[];
  bool fail = false;
  bool missing = false;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    calls.add(movieId);
    if (fail || missing) {
      throw DioException(
        requestOptions: RequestOptions(path: '/movie/$movieId'),
        response: missing
            ? Response(requestOptions: RequestOptions(), statusCode: 404)
            : null,
        type: missing
            ? DioExceptionType.badResponse
            : DioExceptionType.connectionError,
      );
    }
    return TmdbMovieDto(id: movieId, title: '영화 $movieId');
  }
}

RatingDto rating(int id, {int movieId = 550}) => RatingDto(
  ratingId: id,
  movieId: movieId,
  score: 5,
  comment: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('nickname/email duplicate values restore errors without a new request; submit requires both checks', () async {
    final service = FixtureSignUpService(delay: Duration.zero);
    final vm = SignUpViewModel(service);
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('수현');
    await vm.checkNickname('수현');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(vm.canCheckNickname, isFalse);
    await vm.checkNickname('수현');
    expect(service.nicknameRequests.length, 1);
    vm.onNicknameChanged('새닉네임');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    expect(vm.nicknameErrorText, isNull);
    expect(vm.canCheckNickname, isTrue);
    vm.onNicknameChanged(' 수현 ');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(service.nicknameRequests.length, 1);
    vm.onEmailChanged('noco@umc.com');
    await vm.checkEmail('noco@umc.com');
    vm.onEmailChanged('new@example.com');
    vm.onEmailChanged('noco@umc.com');
    expect(vm.emailCheckStatus, CheckStatus.duplicated);
    expect(service.emailRequests.length, 1);
    vm.onNicknameChanged('새닉네임');
    vm.onEmailChanged('new@example.com');
    vm.onPasswordChanged('Valid123!');
    vm.onTermsChanged(true);
    expect(vm.canSubmit, isFalse);
    await vm.checkNickname('새닉네임');
    await vm.checkEmail('new@example.com');
    expect(vm.canSubmit, isTrue);
    vm.onEmailChanged('other@example.com');
    expect(vm.emailCheckStatus, CheckStatus.idle);
    expect(vm.canSubmit, isFalse);
    vm.dispose();
  });
  test('each field has independent request versions; obsolete result cannot overwrite current input', () async {
    final service = ControlledChecks();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('이전닉네임');
    vm.onEmailChanged('new@example.com');
    final old = vm.checkNickname('이전닉네임');
    final email = vm.checkEmail('new@example.com');
    expect(vm.nicknameCheckStatus, CheckStatus.checking);
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('다른닉네임');
    final current = vm.checkNickname('다른닉네임');
    service.emails.single.complete(true);
    await email;
    expect(vm.emailCheckStatus, CheckStatus.available);
    service.nicknames[1].complete(true);
    await current;
    service.nicknames.first.complete(false);
    await old;
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    expect(vm.nicknameErrorText, isNull);
    vm.onNicknameChanged('이전닉네임');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    vm.dispose();
  });
  test(
    'network failure differs from duplicate and in-flight disposal is safe',
    () async {
      final service = FixtureSignUpService(fail: true, delay: Duration.zero);
      final vm = SignUpViewModel(service)..onNicknameChanged('새닉네임');
      await vm.checkNickname('새닉네임');
      expect(vm.nicknameCheckStatus, CheckStatus.error);
      expect(vm.nicknameErrorText, contains('실패'));
      expect(vm.canCheckNickname, isTrue);
      service.fail = false;
      await vm.checkNickname('새닉네임');
      expect(vm.nicknameCheckStatus, CheckStatus.available);
      vm.dispose();
      final controlled = ControlledChecks();
      final disposed = SignUpViewModel(controlled)
        ..onEmailChanged('new@example.com');
      final pending = disposed.checkEmail('new@example.com');
      disposed.dispose();
      controlled.emails.single.complete(true);
      await pending;
    },
  );
  test('ratings preserve null comments, deduplicate/cache detail lookups and use sample member 1', () async {
    final service = StubRatings()
      ..fetch = () async => [rating(3), rating(2), rating(1, movieId: 155)];
    final movies = StubMovies();
    final vm = MyRatingsViewModel(service, movies, 1);
    await vm.load();
    expect(service.ids, [1]);
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.ratings.length, 3);
    expect(vm.ratings.first.rating.comment, isNull);
    expect(movies.calls, [550, 155]);
    await vm.load();
    expect(movies.calls, [550, 155]);
    vm.dispose();
  });
  test('TMDB network failures keep ratings and are retried on next load; 404 is cached', () async {
    final service = StubRatings()..fetch = () async => [rating(2), rating(1)];
    final movies = StubMovies()..fail = true;
    final vm = MyRatingsViewModel(service, movies, 1);
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.ratings.length, 2);
    expect(vm.ratings.first.movie, isNull);
    expect(vm.message, contains('평점 기록'));
    expect(movies.calls, [550]);
    movies.fail = false;
    await vm.load();
    expect(vm.ratings.first.movie?.id, 550);
    expect(vm.message, isNull);
    vm.dispose();
    final missing = StubMovies()..missing = true;
    final missingVm = MyRatingsViewModel(service, missing, 1);
    await missingVm.load();
    await missingVm.load();
    expect(missing.calls, [550]);
    missingVm.dispose();
  });
  test('ratings empty/error and newest-request wins; disposed pending request is ignored', () async {
    final service = StubRatings()..fetch = () async => [];
    final vm = MyRatingsViewModel(service, StubMovies(), 1);
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.empty);
    service.fetch = () async => throw DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: 404,
        data: {
          'isSuccess': false,
          'code': 'COMMON404',
          'message': '존재하지 않는 회원입니다.',
          'result': null,
        },
      ),
    );
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.error);
    expect(vm.message, '존재하지 않는 회원입니다.');
    final first = Completer<List<RatingDto>>();
    service.fetch = () => first.future;
    final older = vm.load();
    expect(vm.status, MyRatingsLoadStatus.loading);
    service.fetch = () async => [rating(9)];
    await vm.load();
    first.complete([rating(1)]);
    await older;
    expect(vm.ratings.single.rating.ratingId, 9);
    final second = Completer<List<RatingDto>>();
    service.fetch = () => second.future;
    final pending = vm.load();
    vm.dispose();
    second.complete([]);
    await pending;
  });
}
