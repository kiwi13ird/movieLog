import '../view_models/auth_view_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/movielog_button.dart';
import 'movie_detail_screen.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    required this.movieId,
    this.initialMovie,
    super.key,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late Future<TmdbMovieDto> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TmdbMovieDto> _load() => widget.initialMovie != null
      ? Future.value(widget.initialMovie!)
      : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  @override
  Widget build(BuildContext context) => FutureBuilder<TmdbMovieDto>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(title: const Text('영화 상세')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('영화를 불러오지 못했습니다.'),
                const SizedBox(height: 16),
                MovieLogButton(
                  label: '다시 시도',
                  onPressed: () => setState(() => _future = _load()),
                ),
              ],
            ),
          ),
        );
      }
      return ChangeNotifierProvider(
        create: (context) => MovieDetailViewModel(
          null,
          null,
          snapshot.data!,
          auth: context.read<AuthViewModel>(),
        ),
        child: const MovieDetailScreen(),
      );
    },
  );
}
