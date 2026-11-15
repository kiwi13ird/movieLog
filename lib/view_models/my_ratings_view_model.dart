import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movies, this.memberId);
  final RatingApiService _service;
  final TmdbMovieService _movies;
  final int memberId;
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
    if (_disposed) return;
    final version = ++_version;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final raw = await _service.fetchMyRatings(memberId);
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
    } on DioException catch (error) {
      if (_disposed || version != _version) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      if (_disposed || version != _version) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 응답을 확인하지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _version) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    _movieCache.clear();
    super.dispose();
  }
}
