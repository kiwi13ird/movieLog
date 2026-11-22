import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_detail_view_model.dart';
import '../widgets/favorite_button.dart';
import '../widgets/movie_poster.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _favorite = false;
  Future<void> _rate(MovieDetailViewModel vm) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) =>
            vm.createRating(score: score, comment: comment),
      ),
    );
    if (mounted && saved == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(vm.submitMessage ?? '평점이 등록되었습니다.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<MovieDetailViewModel>(
    builder: (context, vm, child) {
      final movie = vm.movie.toMovie(const []);
      return PopScope(
        canPop: !vm.busy,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('영화 상세'),
            leading: BackButton(
              key: const Key('detailBackButton'),
              onPressed: vm.busy ? null : () => context.pop(),
            ),
            actions: [
              FavoriteButton(
                isFavorite: _favorite,
                onPressed: () {
                  setState(() => _favorite = !_favorite);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          _favorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.',
                        ),
                      ),
                    );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(child: MoviePoster(movie: movie, width: 180, height: 250)),
              const SizedBox(height: 24),
              Text(
                movie.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TMDB 영화 ID ${vm.movie.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777183)),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('평균 평점')),
              const SizedBox(height: 8),
              Center(
                child: RatingBarIndicator(
                  rating: movie.voteAverage / 2,
                  itemCount: 5,
                  itemSize: 28,
                  itemBuilder: (_, _) =>
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('openRatingDialogButton'),
                onPressed: vm.canRate && !vm.busy ? () => _rate(vm) : null,
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('평점 남기기'),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    movie.overview.isEmpty ? '줄거리 정보가 없습니다.' : movie.overview,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
