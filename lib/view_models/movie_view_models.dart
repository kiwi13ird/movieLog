import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this.service);
  final TmdbMovieService service;
  List<TmdbMovieDto> movies = const [];
  List<TmdbMovieDto> _lastSuccess = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  MovieLoadStatus status = MovieLoadStatus.idle;
  bool busy = false;
  bool _disposed = false;
  int _version = 0;
  int failureVersion = 0;

  Future<void> selectGenres(List<int> ids) async {
    if (busy) return;
    selectedGenreIds = ids.isEmpty ? null : List.unmodifiable(ids);
    await load(clear: true);
  }

  Future<void> load({bool clear = false}) async {
    if (busy || _disposed) return;
    final version = ++_version;
    final ids = selectedGenreIds;
    busy = true;
    status = MovieLoadStatus.loading;
    if (clear) movies = const [];
    notifyListeners();
    try {
      if (genres.isEmpty) {
        final result = await service.fetchGenres();
        if (_disposed || version != _version) return;
        genres = result;
      }
      final byId = <int, TmdbMovieDto>{};
      var pageNumber = 1;
      while (byId.length < 30) {
        final page = await service.discoverMovies(
          page: pageNumber,
          genreIds: ids,
        );
        if (_disposed || version != _version) return;
        for (final movie in page.results) {
          byId[movie.id] = movie;
          if (byId.length == 30) break;
        }
        if (page.results.isEmpty || pageNumber >= page.totalPages) break;
        pageNumber++;
      }
      movies = List.unmodifiable(byId.values);
      _lastSuccess = movies;
      status = movies.isEmpty ? MovieLoadStatus.empty : MovieLoadStatus.success;
      if (kDebugMode) {
        debugPrint('[TMDB 목록] 총 ${movies.length}개 / 고유 ID ${byId.length}개');
      }
    } catch (_) {
      if (_disposed || version != _version) return;
      movies = _lastSuccess;
      status = movies.isEmpty ? MovieLoadStatus.error : MovieLoadStatus.success;
      failureVersion++;
    } finally {
      if (!_disposed && version == _version) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this.service);
  final TmdbMovieService service;
  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  MovieLoadStatus status = MovieLoadStatus.idle;
  bool _disposed = false;
  Future<void> load() async {
    if (status == MovieLoadStatus.loading || _disposed) return;
    status = MovieLoadStatus.loading;
    notifyListeners();
    try {
      final page = await service.fetchPopular();
      if (_disposed) return;
      final genreResult = await service.fetchGenres();
      if (_disposed) return;
      genres = genreResult;
      movies = page.results.take(5).toList();
      status = movies.isEmpty ? MovieLoadStatus.empty : MovieLoadStatus.success;
    } catch (_) {
      if (_disposed) return;
      status = MovieLoadStatus.error;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
