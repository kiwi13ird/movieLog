import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/session_api_service.dart';
import 'package:movielog/data/services/fixture_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'support/session_fixture.dart';

class CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object? data = {'isSuccess': true, 'result': null};
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class DelayedTokens extends MemoryTokens {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> saveAccessToken(String value) async {
    started.complete();
    await release.future;
    token = value;
  }
}

void main() {
  test('Bearer is attached only to exact protected origin/path, never public, TMDB or foreign hosts', () async {
    final adapter = CaptureAdapter();
    final storage = MemoryTokens()..token = 'test-only';
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(storage, () => 1));
    for (final path in ['/v7/members/me', '/v7/ratings', '/v7/ratings/42']) {
      await dio.get<dynamic>(path);
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer test-only',
      );
    }
    for (final path in [
      '/v7/auth/login',
      '/v7/members/1/ratings',
      '/v7/ratings/42/extra',
      'https://api.themoviedb.org/3/movie/popular',
      'https://workbook.devnoco.com.evil.invalid/v7/ratings',
      'http://workbook.devnoco.com/v7/ratings',
    ]) {
      await dio.get<dynamic>(path);
      expect(
        adapter.requests.last.headers.containsKey('Authorization'),
        isFalse,
      );
    }
  });
  test('v7 create/PATCH parse returned Rating; DELETE expects wrapper 200; public list has no JWT', () async {
    final publicAdapter = CaptureAdapter(), protectedAdapter = CaptureAdapter();
    final public = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = publicAdapter;
    final protected = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = protectedAdapter;
    final api = SessionApiService(public, protected);
    protectedAdapter.status = 201;
    protectedAdapter.data = {
      'isSuccess': true,
      'result': {
        'ratingId': 42,
        'movieId': 550,
        'score': 4,
        'comment': '서버 후기',
        'createdAt': '2026-01-01',
        'updatedAt': '2026-01-02',
      },
    };
    final rating = await api.ratings.create(
      CreateRatingRequest(movieId: 550, score: 4, comment: '후기'),
    );
    expect(rating.ratingId, 42);
    expect(protectedAdapter.requests.last.path, '/v7/ratings');
    expect(
      (protectedAdapter.requests.last.data as Map).containsKey('memberId'),
      false,
    );
    protectedAdapter.status = 200;
    await api.ratings.update(rating, 4, '서버 후기');
    expect(protectedAdapter.requests.last.data, {
      'score': 4,
      'comment': '서버 후기',
    });
    protectedAdapter.data = {'isSuccess': true, 'result': null};
    await api.ratings.delete(42);
    protectedAdapter.status = 204;
    await expectLater(api.ratings.delete(42), throwsA(isA<ApiFailure>()));
    publicAdapter.data = <dynamic>[];
    await api.ratings.fetchMemberRatings(77);
    expect(publicAdapter.requests.last.path, '/v7/members/77/ratings');
    expect(
      publicAdapter.requests.last.headers.containsKey('Authorization'),
      false,
    );
  });
  test(
    'restore verifies me; transient failure preserves token and allows retry',
    () async {
      final api = SessionFixtureApi()..error = StateError('offline');
      final storage = MemoryTokens()..token = 'test-only';
      final auth = AuthViewModel(api, storage);
      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, isNotNull);
      api.error = null;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member!.nickname, '검증회원');
    },
  );
  test('login credential failure does not expire session; protected 401 does once; 403/409 preserve it', () async {
    final api = SessionFixtureApi()
      ..error = const ApiFailure('입력 오류', code: 'AUTH401_1');
    final storage = MemoryTokens();
    final auth = AuthViewModel(api, storage);
    await auth.login('a@example.com', 'test-only');
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.consumeSessionExpired(), false);
    api.error = null;
    await auth.login('a@example.com', 'test-only');
    for (final code in ['RATING403_1', 'RATING409_1', 'MEMBER409_1']) {
      expect(
        await auth.handleFailure(
          ApiFailure('거부', code: code),
          auth.sessionVersion,
        ),
        false,
      );
      expect(auth.status, AuthStatus.signedIn);
    }
    final version = auth.sessionVersion;
    await Future.wait([
      auth.handleFailure(const ApiFailure('만료', code: 'AUTH401_4'), version),
      auth.handleFailure(const ApiFailure('만료', code: 'AUTH401_4'), version),
    ]);
    expect(auth.status, AuthStatus.signedOut);
    expect(storage.token, isNull);
    expect(auth.consumeSessionExpired(), true);
    expect(auth.consumeSessionExpired(), false);
    await auth.login('b@example.com', 'test-only');
    await auth.handleFailure(
      const ApiFailure('이전 만료', code: 'AUTH401_4'),
      version,
    );
    expect(auth.status, AuthStatus.signedIn);
  });
  test('old member and rating responses after logout/account switch cannot repopulate session', () async {
    final api = SessionFixtureApi()..pendingMember = Completer<MemberInfo>();
    final auth = AuthViewModel(api, MemoryTokens()..token = 'test-only');
    final restoring = auth.restoreSession();
    await Future<void>.delayed(Duration.zero);
    await auth.logout();
    api.pendingMember!.complete(member('이전회원'));
    await restoring;
    expect(auth.member, isNull);
    api.pendingMember = null;
    await auth.login('new@example.com', 'test-only');
    final movies = await FixtureMovieService('posters').fetchPopular();
    api.pendingRating = Completer();
    final writing = auth.createRating(movies.results.first, 4, '후기');
    await auth.logout();
    await auth.login('next@example.com', 'test-only');
    api.pendingRating!.complete(api.rating(4, '후기'));
    await writing;
    expect(auth.ratings, isEmpty);
    expect(auth.status, AuthStatus.signedIn);
  });
  test('logout waits for in-flight secure write and blocks login until deletion completes', () async {
    final storage = DelayedTokens();
    final auth = AuthViewModel(SessionFixtureApi(), storage);
    final login = auth.login('fixture@example.com', 'non-secret');
    await storage.started.future;
    final logout = auth.logout();
    expect(auth.storageCleanupInProgress, true);
    await auth.login('other@example.com', 'non-secret');
    expect(auth.status, AuthStatus.signedOut);
    storage.release.complete();
    await Future.wait([login, logout]);
    expect(storage.token, isNull);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.consumeSessionExpired(), false);
  });
}
