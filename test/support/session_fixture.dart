import 'package:movielog/data/services/rating_api_service.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/core/auth/token_storage.dart';
import 'package:movielog/data/services/session_api_service.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class MemoryTokens implements TokenStorage {
  String? token;
  bool failRead = false, failDelete = false;
  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('storage');
    return token;
  }

  @override
  Future<void> saveAccessToken(String value) async {
    token = value;
  }

  @override
  Future<void> deleteAccessToken() async {
    if (failDelete) throw StateError('storage');
    token = null;
  }
}

MemberInfo member([String nickname = '검증회원']) => MemberInfo.fromJson({
  'email': 'fixture@example.com',
  'nickname': nickname,
  'createdAt': '2026-10-10T00:00:00',
});

class SessionFixtureApi extends SessionApiService {
  SessionFixtureApi() : super(Dio(), Dio());
  @override
  RatingApiService get ratings => FixtureRatings(this);
  Object? error;
  Completer<MemberInfo>? pendingMember;
  Completer<RatingDto>? pendingRating;
  String nickname = '검증회원';
  int meCalls = 0;
  void check() {
    if (error != null) throw error!;
  }

  @override
  Future<String> login(String email, String password) async {
    check();
    return 'test-only-opaque-value';
  }

  @override
  Future<MemberInfo> fetchMe() async {
    meCalls++;
    if (pendingMember != null) return pendingMember!.future;
    check();
    return member(nickname);
  }

  @override
  Future<MemberInfo> updateNickname(String value) async {
    check();
    nickname = value;
    return member(value);
  }

  RatingDto rating(int score, String? comment) => RatingDto(
    ratingId: 42,
    movieId: 1,
    score: score,
    comment: comment,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  Future<RatingDto> create(CreateRatingRequest request) async {
    if (pendingRating != null) return pendingRating!.future;
    check();
    return rating(request.score, request.comment);
  }

  Future<RatingDto> update(RatingDto r, int score, String? comment) async {
    check();
    return rating(score, comment);
  }

  Future<void> delete(int id) async {
    check();
  }
}

AuthViewModel signedInFixture() =>
    AuthViewModel(
        SessionFixtureApi(),
        MemoryTokens()..token = 'test-only-opaque-value',
      )
      ..status = AuthStatus.signedIn
      ..member = member()
      ..memberStatus = MemberLoadStatus.success;

class FixtureRatings extends RatingApiService {
  FixtureRatings(this.owner) : super(Dio(), Dio());
  final SessionFixtureApi owner;
  @override
  Future<RatingDto> create(CreateRatingRequest request) =>
      owner.create(request);
  @override
  Future<RatingDto> update(RatingDto rating, int score, String? comment) =>
      owner.update(rating, score, comment);
  @override
  Future<void> delete(int id) => owner.delete(id);
}
