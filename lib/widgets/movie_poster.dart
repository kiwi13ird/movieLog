import 'package:flutter/material.dart';

import '../models/movie.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    required this.movie,
    this.width = 96,
    this.height = 132,
    super.key,
  });

  final Movie movie;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = <List<Color>>[
      [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      [const Color(0xFF2D3436), const Color(0xFF636E72)],
      [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
      [const Color(0xFFD63031), const Color(0xFF2D3436)],
    ];
    final palette = colors[movie.id.hashCode.abs() % colors.length];

    return Container(
      key: ValueKey(movie.posterAsset),
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: movie.posterUrl == null
          ? const Icon(
              Icons.movie_creation_outlined,
              color: Colors.white,
              size: 38,
            )
          : Image.network(
              movie.posterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 38,
              ),
            ),
    );
  }
}
