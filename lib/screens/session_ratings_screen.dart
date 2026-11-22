import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/movie_poster.dart';

class SessionRatingsScreen extends StatelessWidget {
  const SessionRatingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('현재 세션의 평점')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '이번 로그인에서 등록한 평점만 표시해요. 서버에서 전체 내 평점을 조회하는 API는 아직 제공되지 않습니다.',
          ),
          if (auth.ratings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('영화 상세에서 첫 평점을 남겨보세요.'),
            ),
          for (final rating in auth.ratings)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (auth.movieFor(rating.movieId) case final movie?)
                      MoviePoster(
                        movie: movie.toMovie(const []),
                        width: 80,
                        height: 110,
                      ),
                    Text(
                      auth.movieFor(rating.movieId)?.title ??
                          '영화 #${rating.movieId}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('${rating.score} / 5 · ${rating.comment ?? "코멘트 없음"}'),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => RatingDialog(
                              initialScore: rating.score,
                              initialComment: rating.comment,
                              onSubmit: (score, comment) =>
                                  auth.updateRating(rating, score, comment),
                            ),
                          ),
                          child: const Text('수정'),
                        ),
                        TextButton(
                          onPressed: () => showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => DeleteRatingDialog(
                              onConfirm: () =>
                                  auth.deleteRating(rating.ratingId),
                            ),
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
