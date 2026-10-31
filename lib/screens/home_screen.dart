import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_view_models.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Consumer<MovieHomeViewModel>(
      builder: (context, vm, child) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '오늘은 어떤 영화를\n기록해 볼까요?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Text('인기 영화를 확인해 보세요.'),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '인기 영화 ${vm.movies.length}개',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/movies'),
                child: const Text('전체보기'),
              ),
            ],
          ),
          if (vm.status == MovieLoadStatus.loading)
            const SizedBox(height: 220, child: MovieListLoading()),
          if (vm.status == MovieLoadStatus.error)
            MovieListError(onRetry: () => vm.load()),
          if (vm.status == MovieLoadStatus.empty)
            const SizedBox(height: 220, child: MovieListEmpty()),
          for (final dto in vm.movies)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MovieCard(
                movie: dto.toMovie(vm.genres),
                onTap: () => context.push(
                  '/movies/${dto.id}',
                  extra: dto.toMovie(vm.genres),
                ),
              ),
            ),
          const Text(
            'This product uses the TMDB API but is not endorsed or certified by TMDB.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
