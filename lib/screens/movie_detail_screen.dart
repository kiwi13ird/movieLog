import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/favorite_button.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({required this.movieId, super.key});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double _rating = 0;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        ),
      );
  }

  Future<void> _showRatingDialog(Movie movie) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${movie.title} 평점'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MovieRatingInput(
                rating: _rating,
                onRatingUpdate: (rating) {
                  setState(() => _rating = rating);
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 14),
              Text(_rating == 0 ? '별을 눌러 평점을 선택해 주세요.' : '$_rating / 5.0'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: _rating > 0
                  ? () => Navigator.of(dialogContext).pop()
                  : null,
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);
    if (movie == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('영화 정보를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          key: const Key('detailBackButton'),
          onPressed: () => context.pop(),
        ),
        title: const Text('영화 상세'),
        actions: [
          FavoriteButton(isFavorite: _isFavorite, onPressed: _toggleFavorite),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(child: MoviePoster(movie: movie, width: 180, height: 250)),
          const SizedBox(height: 26),
          Text(
            movie.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${movie.genre} · ${movie.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6F6B78), fontSize: 16),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text('평균 평점', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyedSubtree(
                  key: const Key('averageRatingIndicator'),
                  child: RatingBarIndicator(
                    rating: 4.5,
                    itemCount: 5,
                    itemSize: 28,
                    unratedColor: const Color(0xFFE1DFE8),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '4.5',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              key: const Key('openRatingDialogButton'),
              onPressed: () => _showRatingDialog(movie),
              icon: const Icon(Icons.star_outline_rounded),
              label: Text(_rating > 0 ? '내 평점 $_rating점' : '평점 남기기'),
            ),
          ),
          const SizedBox(height: 22),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '이 화면은 공통 Mock Movie 데이터의 ID를 기준으로 영화 정보를 표시합니다.',
                style: TextStyle(height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
