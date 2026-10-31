import 'package:flutter/foundation.dart';

import 'data/services/fixture_movie_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'data/services/tmdb_movie_service.dart';
import 'models/movie.dart';
import 'view_models/movie_view_models.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movie_list_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/start_screen.dart';
import 'widgets/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({this.initialLocation = '/', this.service, super.key});

  final TmdbMovieService? service;

  final String initialLocation;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(
        path: '/',
        name: 'start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainScreen(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => ChangeNotifierProvider(
              create: (context) =>
                  MovieHomeViewModel(context.read<TmdbMovieService>())..load(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            name: 'movies',
            builder: (context, state) => ChangeNotifierProvider(
              create: (context) =>
                  MovieListViewModel(context.read<TmdbMovieService>())..load(),
              child: const MovieListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':movieId',
                name: 'movieDetail',
                builder: (context, state) => MovieDetailScreen(
                  movieId: state.pathParameters['movieId']!,
                  movie: state.extra is Movie ? state.extra as Movie : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/my',
            name: 'myPage',
            builder: (context, state) => const MyPageScreen(),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C5CE7);
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE4E1EC)),
    );

    return Provider<TmdbMovieService>(
      create: (_) => widget.service ?? createService(),
      child: MaterialApp.router(
        builder: (context, child) {
          const mode = String.fromEnvironment('TMDB_FIXTURE');
          return kDebugMode && mode.isNotEmpty
              ? Banner(
                  message: 'FIXTURE',
                  location: BannerLocation.topEnd,
                  child: child!,
                )
              : child!;
        },
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        routerConfig: _router,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: purple),
          scaffoldBackgroundColor: const Color(0xFFF8F7FC),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: roundedBorder,
            enabledBorder: roundedBorder,
            focusedBorder: roundedBorder.copyWith(
              borderSide: const BorderSide(color: purple, width: 2),
            ),
            errorBorder: roundedBorder.copyWith(
              borderSide: const BorderSide(color: Color(0xFFE5484D)),
            ),
            focusedErrorBorder: roundedBorder.copyWith(
              borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

TmdbMovieService createService() {
  const mode = String.fromEnvironment('TMDB_FIXTURE');
  if (kDebugMode && mode.isNotEmpty) return FixtureMovieService(mode);
  return TmdbMovieService(createTmdbClient());
}
