import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
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
          const Text(
            '추천 영화를 확인해 보세요.',
            style: TextStyle(color: Color(0xFF6F6B78), fontSize: 16),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 추천',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => context.go('/movies'),
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...mockMovies
              .take(3)
              .map(
                (movie) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MovieCard(
                    movie: movie,
                    onTap: () => context.push('/movies/${movie.id}'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
