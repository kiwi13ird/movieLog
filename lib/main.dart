import 'package:dio/dio.dart';

import 'core/network/movie_log_client.dart';
import 'view_models/learning_member_session.dart';
import 'data/models/sign_up_models.dart';
import 'data/models/tmdb_movie_dto.dart';
import 'data/services/week07_fixture_adapter.dart';
import 'screens/movie_detail_loader.dart';
import 'data/services/sign_up_service.dart';
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
import 'view_models/movie_view_models.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
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
    this.session,
    super.key,
  });

  final LearningMemberSession? session;
  final SignUpService? memberService;
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
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
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
                builder: (context, state) {
                  final id = int.tryParse(
                    state.pathParameters['movieId'] ?? '',
                  );
                  if (id == null || id < 1) {
                    return const Scaffold(
                      body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
                    );
                  }
                  final extra = state.extra;
                  return MovieDetailLoader(
                    key: ValueKey(id),
                    movieId: id,
                    initialMovie: extra is TmdbMovieDto && extra.id == id
                        ? extra
                        : null,
                  );
                },
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
                builder: (context, state) {
                  final id = context.watch<LearningMemberSession>().memberId;
                  if (id == null) {
                    return Scaffold(
                      appBar: AppBar(
                        centerTitle: true,
                        title: const Text('내가 등록한 평점'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('학습용 회원가입이 필요합니다.'),
                            TextButton(
                              onPressed: () => context.push('/signup'),
                              child: const Text('회원가입하기'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ChangeNotifierProvider(
                    key: ValueKey(id),
                    create: (context) => MyRatingsViewModel(
                      context.read<RatingApiService>(),
                      context.read<TmdbMovieService>(),
                      id,
                    )..load(),
                    child: const MyRatingsScreen(),
                  );
                },
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
    const week07Mode = String.fromEnvironment('WEEK07_FIXTURE');
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) {
            final dio = createMovieLogClient();
            if (kDebugMode && week07Mode.isNotEmpty) {
              final adapter = Week07FixtureAdapter(week07Mode);
              if (week07Mode != 'empty') adapter.seed();
              dio.httpClientAdapter = adapter;
            }
            return dio;
          },
          dispose: (_, dio) => dio.close(force: true),
        ),
        if (widget.session != null)
          ChangeNotifierProvider<LearningMemberSession>.value(
            value: widget.session!,
          )
        else
          ChangeNotifierProvider<LearningMemberSession>(
            create: (_) {
              final session = LearningMemberSession();
              if (kDebugMode &&
                  week07Mode.isNotEmpty &&
                  week07Mode != 'signup-409' &&
                  week07Mode != 'password-400') {
                session.setMember(
                  const SignUpResult(
                    memberId: 9001,
                    email: 'fixture@example.com',
                    nickname: '검증회원',
                  ),
                );
              }
              return session;
            },
          ),
        Provider<TmdbMovieService>(
          create: (_) => widget.service ?? createService(),
        ),
        Provider<SignUpService>(
          create: (context) =>
              widget.memberService ??
              (kDebugMode && week06Mode.isNotEmpty
                  ? FixtureSignUpService(fail: week06Mode == 'error')
                  : SignUpService(context.read<Dio>())),
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
          return kDebugMode &&
                  (mode.isNotEmpty ||
                      week06Mode.isNotEmpty ||
                      week07Mode.isNotEmpty)
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
  const week07Mode = String.fromEnvironment('WEEK07_FIXTURE');
  if (kDebugMode && week07Mode.isNotEmpty) {
    return Week06FixtureMovieService('success');
  }
  const week06Mode = String.fromEnvironment('WEEK06_FIXTURE');
  if (kDebugMode && week06Mode.isNotEmpty) {
    return Week06FixtureMovieService(week06Mode);
  }
  const mode = String.fromEnvironment('TMDB_FIXTURE');
  if (kDebugMode && mode.isNotEmpty) return FixtureMovieService(mode);
  return TmdbMovieService(createTmdbClient());
}
