import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movielog_button.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('내가 등록한 평점'),
      centerTitle: true,
      leading: BackButton(
        key: const Key('ratingsBackButton'),
        onPressed: () => context.pop(),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Text(
              '학습용 회원(memberId 1)의 공개 평점입니다.',
              style: TextStyle(color: Color(0xFF777183)),
            ),
          ),
          Expanded(
            child: Consumer<MyRatingsViewModel>(
              builder: (context, vm, child) => switch (vm.status) {
                MyRatingsLoadStatus.idle ||
                MyRatingsLoadStatus.loading => const Center(
                  key: Key('ratingsLoading'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('평점을 불러오는 중이에요.'),
                    ],
                  ),
                ),
                MyRatingsLoadStatus.empty => const Center(
                  key: Key('ratingsEmpty'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_border_rounded,
                        size: 48,
                        color: Color(0xFF9B90B0),
                      ),
                      SizedBox(height: 16),
                      Text('등록된 평점이 없습니다.'),
                    ],
                  ),
                ),
                MyRatingsLoadStatus.error => Center(
                  key: const Key('ratingsError'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 44),
                        const SizedBox(height: 16),
                        Text(
                          vm.message ?? '평점을 불러오지 못했습니다.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        MovieLogButton(
                          label: '다시 시도',
                          width: 120,
                          onPressed: vm.load,
                        ),
                      ],
                    ),
                  ),
                ),
                MyRatingsLoadStatus.success => ListView.separated(
                  key: const Key('ratingsSuccess'),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: vm.ratings.length + (vm.message != null ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (vm.message != null && index == 0) {
                      return Text(
                        vm.message!,
                        style: const TextStyle(color: Color(0xFF777183)),
                      );
                    }
                    return _RatingCard(
                      entry: vm.ratings[index - (vm.message != null ? 1 : 0)],
                    );
                  },
                ),
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});
  final RatingWithMovie entry;
  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final date = rating.createdAt.toLocal();
    final day =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Card(
      key: ValueKey('rating-${rating.ratingId}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movie != null)
              MoviePoster(
                movie: movie.toMovie(const []),
                width: 76,
                height: 110,
              )
            else
              Container(
                width: 76,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.movie_creation_outlined,
                  color: Color(0xFF9B90B0),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 정보를 불러올 수 없어요',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '영화 ID ${rating.movieId}',
                    style: const TextStyle(
                      color: Color(0xFF777183),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 21,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.score} / 5',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (rating.comment != null) ...[
                    const SizedBox(height: 10),
                    Text(rating.comment!),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFF777183),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
