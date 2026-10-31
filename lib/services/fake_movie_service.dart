import '../models/movie.dart';

enum MovieLoadMode { success, empty, failure, timeout }

class MovieLoadException implements Exception {
  const MovieLoadException();
}

class FakeMovieService {
  const FakeMovieService();

  // TODO(5주차 유저별 평점 조회 API): 이 호출 경계를 실제 API로 교체한다.
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(
      Duration(seconds: mode == MovieLoadMode.timeout ? 5 : 1),
    );
    return switch (mode) {
      MovieLoadMode.failure => throw const MovieLoadException(),
      MovieLoadMode.empty => const <Movie>[],
      _ => mockMovies,
    };
  }
}
