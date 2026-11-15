import 'package:dio/dio.dart';

import 'core/network/movie_log_client.dart';
import 'core/config/learning_config.dart';
import 'data/services/member_check_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/week06_fixture_services.dart';
import 'view_models/sign_up_view_model.dart';
import 'view_models/my_ratings_view_model.dart';
import 'screens/my_ratings_screen.dart';
import 'screens/button_showcase_screen.dart';

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
  const startRoute = String.fromEnvironment('START_ROUTE', defaultValue: '/');
  runApp(MovieLogApp(initialLocation: kDebugMode ? startRoute : '/'));
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({
    this.initialLocation = '/',
    this.service,
    this.memberService,
    this.ratingService,
    super.key,
  });

  final MemberCheckService? memberService;
  final RatingApiService? ratingService;

  final TmdbMovieService? service;

  final String initialLocation;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        name: 'start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              SignUpViewModel(context.read<MemberCheckService>()),
          child: const SignUpScreen(),
        ),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/button-showcase',
          builder: (context, state) => const ButtonShowcaseScreen(),
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
            routes: [
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (context) => MyRatingsViewModel(
                    context.read<RatingApiService>(),
                    context.read<TmdbMovieService>(),
                    sampleMemberId,
                  )..load(),
                  child: const MyRatingsScreen(),
                ),
              ),
            ],
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

    const week06Mode = String.fromEnvironment('WEEK06_FIXTURE');
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => createMovieLogClient(),
          dispose: (_, dio) => dio.close(force: true),
        ),
        Provider<TmdbMovieService>(
          create: (_) => widget.service ?? createService(),
        ),
        Provider<MemberCheckService>(
          create: (context) =>
              widget.memberService ??
              (kDebugMode && week06Mode.isNotEmpty
                  ? FixtureMemberCheckService(fail: week06Mode == 'error')
                  : MemberCheckService(context.read<Dio>())),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              widget.ratingService ??
              (kDebugMode && week06Mode.isNotEmpty
                  ? FixtureRatingApiService(week06Mode)
                  : RatingApiService(context.read<Dio>())),
        ),
      ],
      child: MaterialApp.router(
        builder: (context, child) {
          const mode = String.fromEnvironment('TMDB_FIXTURE');
          return kDebugMode && (mode.isNotEmpty || week06Mode.isNotEmpty)
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
  const week06Mode = String.fromEnvironment('WEEK06_FIXTURE');
  if (kDebugMode && week06Mode.isNotEmpty) {
    return Week06FixtureMovieService(week06Mode);
  }
  const mode = String.fromEnvironment('TMDB_FIXTURE');
  if (kDebugMode && mode.isNotEmpty) return FixtureMovieService(mode);
  return TmdbMovieService(createTmdbClient());
}
