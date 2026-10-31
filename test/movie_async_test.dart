import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_view_models.dart';

class ControlledService extends TmdbMovieService {
  ControlledService() : super(Dio());
  final calls = <({int page, List<int>? genres})>[];
  bool fail = false;
  bool empty = false;
  Completer<void>? gate;
  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(28, '액션'),
    TmdbGenreDto(35, '코미디'),
  ];
  @override
  Future<TmdbMoviePageDto> fetchPopular() async =>
      TmdbMoviePageDto([const TmdbMovieDto(id: 1, title: '영화')], 1);
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    calls.add((page: page, genres: genreIds));
    await gate?.future;
    if (fail) throw StateError('offline');
    if (empty) return const TmdbMoviePageDto([], 0);
    return TmdbMoviePageDto(
      List.generate(
        20,
        (i) => TmdbMovieDto(id: (page - 1) * 19 + i, title: '영화 $i'),
      ),
      3,
    );
  }
}

void main() {
  test('DTO handles null, snake case and integer score', () {
    final dto = TmdbMovieDto.fromJson({
      'id': 550,
      'title': '영화',
      'poster_path': null,
      'vote_average': 8,
      'genre_ids': [28],
    });
    expect(dto.voteAverage, 8.0);
    expect(dto.toMovie(const []).posterUrl, isNull);
    expect(dto.toMovie(const []).id, '550');
  });
  test('deduplicates pages up to 30; genres refresh from page one', () async {
    final service = ControlledService();
    final vm = MovieListViewModel(service);
    await vm.selectGenres([28, 35]);
    expect(vm.movies.length, 30);
    expect(vm.movies.map((e) => e.id).toSet().length, 30);
    expect(service.calls.map((e) => e.page), [1, 2]);
    expect(service.calls.last.genres, [28, 35]);
    service.calls.clear();
    final old = vm.movies;
    service.gate = Completer<void>();
    final pending = vm.load();
    expect(vm.movies, same(old));
    await vm.selectGenres([35]);
    await vm.load();
    expect(vm.selectedGenreIds, [28, 35]);
    expect(service.calls.length, 1);
    service.gate!.complete();
    await pending;
    expect(service.calls.first.page, 1);
    await vm.selectGenres([]);
    expect(service.calls.last.genres, isNull);
    vm.dispose();
  });
  test(
    'failure restores last success and retry keeps last selected genres',
    () async {
      final service = ControlledService();
      final vm = MovieListViewModel(service);
      await vm.load();
      final old = vm.movies;
      service.fail = true;
      await vm.selectGenres([35]);
      expect(vm.movies, same(old));
      expect(vm.failureVersion, 1);
      service.fail = false;
      service.calls.clear();
      await vm.load();
      expect(service.calls.first.page, 1);
      expect(service.calls.first.genres, [35]);
      expect(vm.status, MovieLoadStatus.success);
      vm.dispose();
    },
  );
  test('empty, initial failure, short popular and disposal are safe', () async {
    final service = ControlledService()..empty = true;
    final vm = MovieListViewModel(service);
    await vm.load();
    expect(vm.status, MovieLoadStatus.empty);
    service.fail = true;
    await vm.load();
    expect(vm.status, MovieLoadStatus.error);
    final home = MovieHomeViewModel(service);
    await home.load();
    expect(home.movies.length, 1);
    service.gate = Completer<void>();
    final pending = vm.load();
    vm.dispose();
    service.gate!.complete();
    await pending;
    home.dispose();
  });
}
