import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    required this.rating,
    required this.onRatingUpdate,
    super.key,
  });

  final double rating;
  final ValueChanged<double> onRatingUpdate;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('movieRatingInput'),
      child: RatingBar.builder(
        initialRating: rating,
        minRating: 0.5,
        allowHalfRating: true,
        itemCount: 5,
        itemSize: 38,
        glow: false,
        unratedColor: const Color(0xFFE1DFE8),
        itemBuilder: (context, _) =>
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
        onRatingUpdate: onRatingUpdate,
      ),
    );
  }
}
