import 'package:flutter/foundation.dart';

import '../core/auth/token_storage.dart';
import '../data/models/api_failure.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/session_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.api, this.storage);
  final SessionApiService api;
  final TokenStorage storage;
  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  int sessionVersion = 0;
  bool sessionExpired = false, storageCleanupInProgress = false;
  bool _disposed = false;
  bool storageCleanupFailed = false;
  Future<void>? _tokenWrite;
  final Map<int, RatingDto> _ratings = {};
  final Map<int, TmdbMovieDto> _movies = {};
  List<RatingDto> get ratings => List.unmodifiable(_ratings.values);
  TmdbMovieDto? movieFor(int id) => _movies[id];
  bool isCurrent(int version) => !_disposed && version == sessionVersion;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool consumeSessionExpired() {
    final value = sessionExpired;
    sessionExpired = false;
    return value;
  }

  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++sessionVersion;
    status = AuthStatus.initializing;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _ratings.clear();
    _movies.clear();
    message = null;
    _notify();
    try {
      final token = await storage.readAccessToken();
      if (!isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final me = await api.fetchMe();
        if (!isCurrent(version)) return;
        member = me;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } catch (e) {
      if (!isCurrent(version)) return;
      if (await handleFailure(e, version)) return;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        storageCleanupFailed ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++sessionVersion;
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _ratings.clear();
    _movies.clear();
    message = null;
    sessionExpired = false;
    _notify();
    var saving = false;
    try {
      final token = await api.login(email, password);
      if (!isCurrent(version)) return;
      saving = true;
      final write = storage.saveAccessToken(token);
      _tokenWrite = write;
      try {
        await write;
      } finally {
        _tokenWrite = null;
      }
      if (!isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } catch (e) {
      if (!isCurrent(version)) return;
      status = AuthStatus.signedOut;
      if (saving) {
        try {
          await storage.deleteAccessToken();
        } catch (_) {
          storageCleanupFailed = true;
        }
        if (!isCurrent(version)) return;
      }
      message = storageCleanupFailed
          ? '인증 정보를 삭제하지 못했어요. 로그아웃을 다시 시도해 주세요.'
          : saving
          ? '로그인 정보를 안전하게 저장하지 못했어요.'
          : ApiFailure.from(e, fallback: '로그인 요청에 실패했어요. 다시 시도해 주세요.').message;
    }
    if (isCurrent(version)) _notify();
  }

  Future<bool> handleFailure(Object error, int version) async {
    if (!isCurrent(version)) return false;
    final code = ApiFailure.from(error).code;
    if (const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(code)) {
      await clear(expired: true);
      return true;
    }
    return false;
  }

  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();
    try {
      final me = await api.fetchMe();
      if (!isCurrent(version)) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } catch (e) {
      if (!isCurrent(version) || await handleFailure(e, version)) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> updateNickname(String nickname) async {
    if (status != AuthStatus.signedIn) throw const ApiFailure('로그인이 필요합니다.');
    final version = sessionVersion;
    if (nickname == member?.nickname) return;
    try {
      final updated = await api.updateNickname(nickname);
      if (!isCurrent(version)) return;
      member = updated;
      _notify();
    } catch (e) {
      await handleFailure(e, version);
      rethrow;
    }
  }

  Future<void> createRating(
    TmdbMovieDto movie,
    int score,
    String? comment,
  ) async {
    await _write(
      () => api.ratings.create(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      ),
      movie: movie,
    );
  }

  Future<void> updateRating(
    RatingDto rating,
    int score,
    String? comment,
  ) async {
    final version = sessionVersion;
    try {
      await _write(() => api.ratings.update(rating, score, comment));
    } catch (e) {
      if (isCurrent(version) && ApiFailure.from(e).code == 'RATING404_1') {
        _ratings.remove(rating.ratingId);
        _notify();
      }
      rethrow;
    }
  }

  Future<void> _write(
    Future<RatingDto> Function() action, {
    TmdbMovieDto? movie,
  }) async {
    if (status != AuthStatus.signedIn) throw const ApiFailure('로그인이 필요합니다.');
    final version = sessionVersion;
    try {
      final rating = await action();
      if (!isCurrent(version)) return;
      _ratings[rating.ratingId] = rating;
      if (movie != null) _movies[movie.id] = movie;
      _notify();
    } catch (e) {
      await handleFailure(e, version);
      rethrow;
    }
  }

  Future<void> deleteRating(int id) async {
    if (status != AuthStatus.signedIn) throw const ApiFailure('로그인이 필요합니다.');
    final version = sessionVersion;
    try {
      await api.ratings.delete(id);
      if (!isCurrent(version)) return;
      _ratings.remove(id);
      _notify();
    } catch (e) {
      if (isCurrent(version) && ApiFailure.from(e).code == 'RATING404_1') {
        _ratings.remove(id);
        _notify();
      }
      await handleFailure(e, version);
      rethrow;
    }
  }

  Future<void> logout() => clear(expired: false);
  Future<void> clear({required bool expired}) async {
    if (storageCleanupInProgress || _disposed) return;
    ++sessionVersion;
    storageCleanupInProgress = true;
    status = AuthStatus.signedOut;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _ratings.clear();
    _movies.clear();
    sessionExpired = expired;
    message = null;
    _notify();
    try {
      try {
        await _tokenWrite;
      } catch (_) {
        /* Still attempt cleanup. */
      }
      await storage.deleteAccessToken();
      storageCleanupFailed = false;
    } catch (_) {
      storageCleanupFailed = true;
      message = '인증 정보를 삭제하지 못했어요. 로그아웃을 다시 시도해 주세요.';
    } finally {
      storageCleanupInProgress = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++sessionVersion;
    super.dispose();
  }
}
