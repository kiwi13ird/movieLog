import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/legacy_rating_api_service.dart';
import 'package:movielog/data/services/week07_fixture_adapter.dart';
import 'package:movielog/data/services/week06_fixture_services.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';

Future<SignUpViewModel> signup(Dio dio) async {
  final vm = SignUpViewModel(SignUpService(dio));
  vm.onNicknameChanged('검증닉네임');
  vm.onEmailChanged('a@example.com');
  await vm.checkNickname('검증닉네임');
  await vm.checkEmail('a@example.com');
  vm.onPasswordChanged('Valid123!');
  vm.onTermsChanged(true);
  return vm;
}

const request = CreateMemberRequest(
  email: 'a@example.com',
  password: 'Valid123!',
  nickname: '검증닉네임',
);
void main() {
  test('signup success ID goes into memory session, final 409 and password-specific 400 stay distinct', () async {
    for (final mode in ['success', 'signup-409', 'password-400']) {
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..httpClientAdapter = Week07FixtureAdapter(mode, delay: Duration.zero);
      final vm = await signup(dio);
      await vm.submit(request);
      if (mode == 'success') {
        expect(vm.createdMemberId, 9001);
        final session = LearningMemberSession()..setMember(vm.createdMember!);
        expect(session.memberId, 9001);
        session.clear();
        expect(session.memberId, isNull);
        session.dispose();
      } else if (mode == 'signup-409') {
        expect(vm.passwordErrorText, isNull);
        expect(vm.snackbarMessage, contains('이메일'));
      } else {
        expect(vm.passwordErrorText, contains('비밀번호'));
        expect(vm.snackbarMessage, isNull);
        vm.onPasswordChanged('Different123!');
        expect(vm.passwordErrorText, isNull);
      }
      vm.dispose();
      dio.close();
    }
  });
  test('signup submitting blocks second POST and invalidation; disposed late response is ignored', () async {
    final adapter = Week07FixtureAdapter(
      'success',
      delay: const Duration(milliseconds: 20),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
      ..httpClientAdapter = adapter;
    final vm = await signup(dio);
    final first = vm.submit(request);
    expect(vm.isSubmitting, isTrue);
    vm.onNicknameChanged('수정시도');
    await vm.submit(request);
    await first;
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    expect(vm.submitStatus, SubmitStatus.success);
    vm.dispose();
    final another = await signup(dio);
    final pending = another.submit(request);
    another.dispose();
    await pending;
    expect(another.createdMember, isNull);
    dio.close();
  });
  test(
    'create uses TMDB id and cannot use a missing learning member',
    () async {
      final adapter = Week07FixtureAdapter('success', delay: Duration.zero);
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..httpClientAdapter = adapter;
      final service = LegacyRatingApiService(dio);
      final vm = MovieDetailViewModel(
        service,
        9001,
        const TmdbMovieDto(id: 550, title: '영화'),
      );
      await vm.createRating(score: 5, comment: '코멘트');
      expect(adapter.requests.single.data['movieId'], 550);
      expect(adapter.requests.single.path, '/v6/members/9001/ratings');
      final missing = MovieDetailViewModel(
        service,
        null,
        const TmdbMovieDto(id: 13, title: '영화'),
      );
      await expectLater(
        missing.createRating(score: 3),
        throwsA(isA<ApiFailure>()),
      );
      expect(adapter.requests.length, 1);
      vm.dispose();
      missing.dispose();
      dio.close();
    },
  );
  test('update success plus GET failure is not a write failure; retry performs GET only', () async {
    final adapter = Week07FixtureAdapter('refresh-error', delay: Duration.zero)
      ..seed();
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
      ..httpClientAdapter = adapter;
    final vm = MyRatingsViewModel(
      LegacyRatingApiService(dio),
      Week06FixtureMovieService('success'),
      9001,
    );
    await vm.load();
    await vm.updateRating(ratingId: 1, score: 2, comment: null);
    expect(vm.refreshError, isNotNull);
    expect(
      vm.ratings.firstWhere((r) => r.rating.ratingId == 1).rating.score,
      2,
    );
    await vm.load();
    expect(vm.refreshError, isNull);
    expect(adapter.requests.where((r) => r.method == 'PATCH').length, 1);
    expect(
      vm.ratings.firstWhere((r) => r.rating.ratingId == 1).rating.comment,
      isNull,
    );
    vm.dispose();
    dio.close();
  });
  test('bulk partial deletion removes successes, keeps failed selection and retries only remaining IDs', () async {
    final adapter = Week07FixtureAdapter('success', delay: Duration.zero)
      ..seed()
      ..failDeleteId = 2;
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
      ..httpClientAdapter = adapter;
    final vm = MyRatingsViewModel(
      LegacyRatingApiService(dio),
      Week06FixtureMovieService('success'),
      9001,
    );
    await vm.load();
    vm.toggleEditing();
    for (final id in [1, 2, 3]) {
      vm.toggleSelection(id);
    }
    await vm.deleteSelected();
    expect(vm.ratings.map((r) => r.rating.ratingId), [2]);
    expect(vm.selectedRatingIds, {2});
    expect(vm.feedback, contains('1개 삭제 실패'));
    expect(vm.busy, isFalse);
    adapter.failDeleteId = null;
    await vm.deleteSelected();
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(
      adapter.requests
          .where((r) => r.method == 'DELETE')
          .map((r) => r.path.split('/').last),
      ['1', '2', '3', '2'],
    );
    vm.dispose();
    dio.close();
  });
  test('successful delete remains removed when refresh fails; new GET cannot reissue DELETE', () async {
    final adapter = Week07FixtureAdapter('refresh-error', delay: Duration.zero)
      ..seed();
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
      ..httpClientAdapter = adapter;
    final vm = MyRatingsViewModel(
      LegacyRatingApiService(dio),
      Week06FixtureMovieService('success'),
      9001,
    );
    await vm.load();
    await vm.deleteRating(1);
    expect(vm.ratings.any((r) => r.rating.ratingId == 1), isFalse);
    expect(vm.refreshError, isNotNull);
    await vm.load();
    expect(adapter.requests.where((r) => r.method == 'DELETE').length, 1);
    vm.dispose();
    dio.close();
  });
}
