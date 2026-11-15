import 'package:dio/dio.dart';

import '../models/tmdb_movie_dto.dart';

class TmdbMovieService {
  TmdbMovieService(this.dio);
  final Dio dio;
  Future<TmdbMoviePageDto> fetchPopular() async => TmdbMoviePageDto.fromJson(
    (await dio.get<Map<String, dynamic>>(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': 1},
    )).data!,
  );
  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );
    return (response.data!['genres'] as List)
        .map((e) => TmdbGenreDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async => TmdbMoviePageDto.fromJson(
    (await dio.get<Map<String, dynamic>>(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        if (genreIds != null && genreIds.isNotEmpty)
          'with_genres': genreIds.join('|'),
      },
    )).data!,
  );
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/movie/$movieId',
      queryParameters: {'language': 'ko-KR'},
    );
    return TmdbMovieDto.fromJson(response.data!);
  }

  Future<TmdbMovieDto?> findMovieById(int movieId) async {
    try {
      return await fetchMovieDetail(movieId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
