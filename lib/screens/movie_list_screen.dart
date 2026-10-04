import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/genre_chip.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String _selectedGenre = '전체';

  List<Movie> get _filteredMovies => _selectedGenre == '전체'
      ? mockMovies
      : mockMovies.where((movie) => movie.genre == _selectedGenre).toList();

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
              FilledButton.tonal(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('닫기'),
              ),
            ],
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
                  onSelected: (_) => setState(() => _selectedGenre = genre),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const Key('movieList'),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              itemCount: _filteredMovies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final movie = _filteredMovies[index];
                return MovieCard(
                  movie: movie,
                  onTap: () => context.push('/movies/${movie.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
