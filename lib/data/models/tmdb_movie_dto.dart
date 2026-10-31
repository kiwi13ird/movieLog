import '../../models/movie.dart';

class TmdbGenreDto {
  const TmdbGenreDto(this.id, this.name);
  final int id;
  final String name;
  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) =>
      TmdbGenreDto((json['id'] as num).toInt(), json['name'] as String);
}

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    this.overview = '',
    this.posterPath,
    this.backdropPath,
    this.popularity = 0,
    this.releaseDate = '',
    this.genreIds = const [],
    this.voteAverage = 0,
  });
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double popularity;
  final String releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) => TmdbMovieDto(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    overview: json['overview'] as String? ?? '',
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    popularity: (json['popularity'] as num? ?? 0).toDouble(),
    releaseDate: json['release_date'] as String? ?? '',
    genreIds: (json['genre_ids'] as List? ?? [])
        .map((e) => (e as num).toInt())
        .toList(),
    voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
  );
  Movie toMovie(List<TmdbGenreDto> genres) => Movie(
    id: '$id',
    title: title,
    genre: genres
        .where((g) => genreIds.contains(g.id))
        .map((g) => g.name)
        .join(' · '),
    year: int.tryParse(releaseDate.split('-').first) ?? 0,
    posterAsset: '',
    posterUrl: posterPath == null || posterPath!.isEmpty
        ? null
        : 'https://image.tmdb.org/t/p/w500$posterPath',
    overview: overview,
    voteAverage: voteAverage,
  );
}

class TmdbMoviePageDto {
  const TmdbMoviePageDto(
    this.results,
    this.totalPages, {
    this.page = 1,
    this.totalResults = 0,
  });
  final List<TmdbMovieDto> results;
  final int totalPages;
  final int page;
  final int totalResults;
  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) =>
      TmdbMoviePageDto(
        (json['results'] as List)
            .map((e) => TmdbMovieDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        (json['total_pages'] as num).toInt(),
        page: (json['page'] as num? ?? 1).toInt(),
        totalResults: (json['total_results'] as num? ?? 0).toInt(),
      );
}
