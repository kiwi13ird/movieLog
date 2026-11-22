import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/rating_dto.dart';
import '../data/models/api_failure.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/legacy_rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movies, this.memberId);
  final LegacyRatingApiService _service;
  final TmdbMovieService _movies;
  final int? memberId;
  bool isWriting = false;
  bool isRefreshing = false;
  String? refreshError;
  String? feedback;
  bool editing = false;
  final Set<int> _selected = {};
  Set<int> get selectedRatingIds => Set.unmodifiable(_selected);
  bool get canManage => memberId != null && memberId! > 0;
  bool get busy => isWriting;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  final Map<int, Future<TmdbMovieDto?>> _pendingMovies = {};
  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  int _version = 0;
  bool _disposed = false;

  Future<TmdbMovieDto?> _lookup(int id) async {
    if (_movieCache.containsKey(id)) return _movieCache[id];
    final pending = _pendingMovies[id];
    if (pending != null) return pending;
    final future = _fetchMovie(id);
    _pendingMovies[id] = future;
    try {
      return await future;
    } finally {
      _pendingMovies.remove(id);
    }
  }

  Future<TmdbMovieDto?> _fetchMovie(int id) async {
    try {
      final movie = await _movies.findMovieById(id);
      if (!_disposed) _movieCache[id] = movie;
      return movie;
    } catch (_) {
      // A movie metadata failure must not erase a valid rating.
      // Transient failures are not cached, so the next load can retry them.
      return null;
    }
  }

  Future<void> load() async {
    if (_disposed || isWriting) return;
    await _load(preserve: ratings.isNotEmpty || refreshError != null);
  }

  Future<void> _load({bool preserve = false}) async {
    if (_disposed || memberId == null) return;
    final version = ++_version;
    isRefreshing = preserve;
    if (!preserve) status = MyRatingsLoadStatus.loading;
    message = null;
    refreshError = null;
    notifyListeners();
    try {
      final raw = await _service.fetchMyRatings(memberId!);
      if (_disposed || version != _version) return;
      final movies = <int, TmdbMovieDto?>{};
      for (final id in raw.map((r) => r.movieId).toSet()) {
        movies[id] = await _lookup(id);
        if (_disposed || version != _version) return;
      }
      ratings = List.unmodifiable(
        raw.map((r) => RatingWithMovie(rating: r, movie: movies[r.movieId])),
      );
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (ratings.any((r) => r.movie == null)) {
        message = '일부 영화 정보를 가져오지 못했어요. 평점 기록은 그대로 표시합니다.';
      }
    } catch (error) {
      if (_disposed || version != _version) return;
      final failure = ApiFailure.from(
        error,
        fallback: '평점을 불러오지 못했습니다. 연결을 확인하고 다시 시도해 주세요.',
      );
      if (preserve) {
        refreshError = '목록을 다시 불러오지 못했어요. 조회만 다시 시도해 주세요. ${failure.message}';
        status = ratings.isEmpty
            ? MyRatingsLoadStatus.empty
            : MyRatingsLoadStatus.success;
      } else {
        status = MyRatingsLoadStatus.error;
        message = failure.message;
      }
    }
    if (!_disposed && version == _version) {
      isRefreshing = false;
      _selected.retainAll(ratings.map((r) => r.rating.ratingId));
      notifyListeners();
    }
  }

  void toggleEditing() {
    if (_disposed || isWriting || isRefreshing || !canManage) return;
    editing = !editing;
    _selected.clear();
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_disposed ||
        !editing ||
        isWriting ||
        !ratings.any((r) => r.rating.ratingId == id)) {
      return;
    }
    if (!_selected.add(id)) _selected.remove(id);
    notifyListeners();
  }

  void _ensureWritable(int ratingId) {
    if (_disposed || !canManage) {
      throw const ApiFailure('먼저 학습용 회원가입을 완료해 주세요.');
    }
    if (isWriting || isRefreshing) throw const ApiFailure('요청 처리 중입니다.');
    if (!ratings.any((r) => r.rating.ratingId == ratingId)) {
      throw const ApiFailure('목록에서 평점을 다시 확인해 주세요.');
    }
  }

  Future<void> _write(
    int ratingId,
    Future<void> Function() action,
    void Function() apply,
  ) async {
    _ensureWritable(ratingId);
    isWriting = true;
    feedback = null;
    notifyListeners();
    try {
      await action();
      if (_disposed) return;
      apply();
      feedback = '저장되었습니다.';
      await _load(preserve: true);
      if (!_disposed && refreshError != null) {
        feedback = '저장은 완료됐지만 목록을 다시 불러오지 못했어요.';
      }
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (!_disposed && failure.shouldRefresh) await _load(preserve: true);
      throw failure;
    } finally {
      if (!_disposed) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) => _write(
    ratingId,
    () => _service.updateRating(
      memberId: memberId!,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ),
    () {
      ratings = ratings
          .map(
            (e) => e.rating.ratingId != ratingId
                ? e
                : RatingWithMovie(
                    movie: e.movie,
                    rating: RatingDto(
                      ratingId: ratingId,
                      movieId: e.rating.movieId,
                      score: score,
                      comment: comment,
                      createdAt: e.rating.createdAt,
                      updatedAt: DateTime.now().toUtc(),
                    ),
                  ),
          )
          .toList();
    },
  );
  Future<void> deleteRating(int ratingId) => _write(
    ratingId,
    () => _service.deleteRating(memberId: memberId!, ratingId: ratingId),
    () {
      ratings = ratings.where((e) => e.rating.ratingId != ratingId).toList();
      _selected.remove(ratingId);
    },
  );
  Future<void> deleteSelected() async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    _ensureWritable(ids.first);
    isWriting = true;
    feedback = null;
    notifyListeners();
    final failed = <int>{};
    var succeeded = 0;
    try {
      for (final id in ids) {
        if (_disposed) return;
        try {
          await _service.deleteRating(memberId: memberId!, ratingId: id);
          if (_disposed) return;
          succeeded++;
          ratings = ratings.where((e) => e.rating.ratingId != id).toList();
          _selected.remove(id);
        } catch (_) {
          failed.add(id);
        }
      }
      if (_disposed) return;
      await _load(preserve: true);
      if (_disposed) return;
      // A failed deletion stays visible and selected, even if the refresh also failed.
      _selected.clear();
      _selected.addAll(
        failed.where((id) => ratings.any((r) => r.rating.ratingId == id)),
      );
      editing = _selected.isNotEmpty;
      feedback = failed.isEmpty
          ? '$succeeded개 평점을 삭제했습니다.'
          : '$succeeded개 삭제, ${failed.length}개 삭제 실패. 남은 항목을 확인하고 다시 시도해 주세요.';
      if (refreshError != null) {
        feedback = '$feedback 목록 조회도 실패했습니다. 조회만 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    _movieCache.clear();
    super.dispose();
  }
}
