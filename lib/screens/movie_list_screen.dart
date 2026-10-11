import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/genre_chip.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String _selectedGenre = '전체';

  final _service = const FakeMovieService();
  final _preference = GenrePreference();
  late Future<List<Movie>> _moviesFuture;
  bool _restoringGenre = true;
  Future<void> _pendingSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadInitial();
  }

  Future<List<Movie>> _loadInitial() async {
    final results = await Future.wait<Object>([
      _loadMovies(MovieLoadMode.success),
      _restoreGenre(),
    ]);
    return results.first as List<Movie>;
  }

  Future<String> _restoreGenre() async {
    try {
      final genre = await _preference.read();
      if (mounted && ['전체', '로맨스', '드라마', 'SF', '액션'].contains(genre)) {
        setState(() => _selectedGenre = genre);
      }
      return genre;
    } catch (_) {
      return '전체';
    } finally {
      if (mounted) setState(() => _restoringGenre = false);
    }
  }

  Future<List<Movie>> _loadMovies(MovieLoadMode mode) async {
    try {
      return await _service
          .fetchMovies(mode: mode)
          .timeout(const Duration(seconds: 3));
    } catch (error, stackTrace) {
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 로드 시도 종료');
    }
  }

  Future<void> _reload([MovieLoadMode mode = MovieLoadMode.success]) async {
    final future = _loadMovies(mode);
    setState(() {
      _moviesFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder에서 사용자 안내와 재시도를 제공한다.
    }
  }

  void _selectGenre(String genre) {
    setState(() => _selectedGenre = genre);
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _preference.save(genre);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장르를 저장하지 못했어요. 다시 선택해 주세요.')),
        );
      }
    });
  }

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '영화 보기 옵션',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const ListTile(
                  leading: Icon(Icons.sort_rounded),
                  title: Text('최신작순'),
                  contentPadding: EdgeInsets.zero,
                ),
                const ListTile(
                  leading: Icon(Icons.star_outline_rounded),
                  title: Text('평점순'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const Text('인증용 Mock 상태'),
                for (final entry in const {
                  MovieLoadMode.success: 'Success 확인',
                  MovieLoadMode.empty: 'Empty 확인',
                  MovieLoadMode.failure: 'Error 확인',
                  MovieLoadMode.timeout: 'Timeout 확인',
                }.entries)
                  ListTile(
                    title: Text(entry.value),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _reload(entry.key);
                    },
                  ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const genres = ['전체', '로맨스', '드라마', 'SF', '액션'];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '영화',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  key: const Key('movieOptionsButton'),
                  tooltip: '영화 보기 옵션',
                  onPressed: _showOptions,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              itemCount: genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = genres[index];
                return GenreChip(
                  label: genre,
                  selected: _selectedGenre == genre,
                  onSelected: _restoringGenre
                      ? null
                      : (_) => _selectGenre(genre),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const MovieListLoading();
                }
                final movies = (snapshot.data ?? const <Movie>[])
                    .where(
                      (movie) =>
                          _selectedGenre == '전체' ||
                          movie.genre == _selectedGenre,
                    )
                    .toList();
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: snapshot.hasError || movies.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: constraints.maxHeight,
                                  child: snapshot.hasError
                                      ? MovieListError(
                                          isTimeout:
                                              snapshot.error
                                                  is TimeoutException,
                                          onRetry: () => _reload(),
                                        )
                                      : const MovieListEmpty(),
                                ),
                              ],
                            );
                          },
                        )
                      : ListView.separated(
                          key: const Key('movieList'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                          itemCount: movies.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final movie = movies[index];
                            return MovieCard(
                              movie: movie,
                              onTap: () => context.push('/movies/${movie.id}'),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
