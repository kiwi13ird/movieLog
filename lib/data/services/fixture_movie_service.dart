import 'package:dio/dio.dart';

import '../models/tmdb_movie_dto.dart';
import 'tmdb_movie_service.dart';

/// Explicit debug-only fixtures; never used by the release service factory.
class FixtureMovieService extends TmdbMovieService {
  FixtureMovieService(this.mode) : super(Dio());
  final String mode;
  bool fail = false;
  final List<({int page, List<int>? genres})> requests = [];
  Future<void> _wait() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (fail || mode == 'error') throw StateError('fixture failure');
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(28, '액션'),
    TmdbGenreDto(35, '코미디'),
    TmdbGenreDto(878, 'SF'),
  ];
  @override
  Future<TmdbMoviePageDto> fetchPopular() => discoverMovies(page: 1);
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    requests.add((
      page: page,
      genres: genreIds == null ? null : List.of(genreIds),
    ));
    await _wait();
    if (mode == 'empty') return const TmdbMoviePageDto([], 0);
    return TmdbMoviePageDto(
      List.generate(
        20,
        (index) => TmdbMovieDto(
          id: (page - 1) * 19 + index + 1,
          title: index == 0
              ? '포스터 없음 (fixture)'
              : index == 1
              ? '포스터 실패 (fixture)'
              : '검증 영화 ${(page - 1) * 19 + index + 1}',
          genreIds: genreIds ?? const [28],
          releaseDate: '2026-01-01',
          posterPath: index == 1 ? '/fixture-missing-poster.jpg' : null,
          voteAverage: 8,
        ),
      ),
      2,
    );
  }
}
