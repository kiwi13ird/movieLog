class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    this.posterUrl,
    this.overview = '',
    this.voteAverage = 0,
  });

  final String id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final String? posterUrl;
  final String overview;
  final double voteAverage;
}

const mockMovies = <Movie>[
  Movie(
    id: 'la-la-land',
    title: '라라랜드',
    genre: '로맨스',
    year: 2016,
    posterAsset: 'assets/images/la_la_land.jpg',
  ),
  Movie(
    id: 'parasite',
    title: '기생충',
    genre: '드라마',
    year: 2019,
    posterAsset: 'assets/images/parasite.jpg',
  ),
  Movie(
    id: 'interstellar',
    title: '인터스텔라',
    genre: 'SF',
    year: 2014,
    posterAsset: 'assets/images/interstellar.jpg',
  ),
  Movie(
    id: 'the-dark-knight',
    title: '다크 나이트',
    genre: '액션',
    year: 2008,
    posterAsset: 'assets/images/the_dark_knight.jpg',
  ),
  Movie(
    id: 'about-time',
    title: '어바웃 타임',
    genre: '로맨스',
    year: 2013,
    posterAsset: 'assets/images/about_time.jpg',
  ),
  Movie(
    id: 'little-forest',
    title: '리틀 포레스트',
    genre: '드라마',
    year: 2018,
    posterAsset: 'assets/images/little_forest.jpg',
  ),
];

Movie? findMovieById(String id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
