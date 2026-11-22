import 'core/auth/token_storage.dart';
import 'core/network/auth_interceptor.dart';
import 'data/services/session_api_service.dart';
import 'view_models/auth_view_model.dart';
import 'screens/login_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/session_ratings_screen.dart';

import 'package:dio/dio.dart';

import 'core/network/movie_log_client.dart';
import 'data/models/tmdb_movie_dto.dart';
import 'screens/movie_detail_loader.dart';
import 'data/services/sign_up_service.dart';
import 'view_models/sign_up_view_model.dart';
import 'screens/button_showcase_screen.dart';

import 'package:flutter/foundation.dart';

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
    this.auth,
    super.key,
  });

  final AuthViewModel? auth;
  final SignUpService? memberService;

  final TmdbMovieService? service;

  final String initialLocation;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final TokenStorage _storage = SecureTokenStorage();
  late final Dio _publicClient = createMovieLogClient();
  late final Dio _authClient = createMovieLogClient()
    ..options.followRedirects = false
    ..interceptors.add(AuthInterceptor(_storage, () => _auth.sessionVersion));
  late final AuthViewModel _auth =
      widget.auth ??
      AuthViewModel(SessionApiService(_publicClient, _authClient), _storage);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _auth.restoreSession();
    });
  }

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: _auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final public = {'/login', '/register', '/signup'}.contains(path);
      return switch (_auth.status) {
        AuthStatus.initializing || AuthStatus.retryRequired =>
          path == '/start' ? null : '/start?from=${Uri.encodeComponent(path)}',
        AuthStatus.signedOut ||
        AuthStatus.authenticating => public ? null : '/login',
        AuthStatus.signedIn =>
          public || path == '/' || path == '/start'
              ? (state.uri.queryParameters['from']?.startsWith('/my') == true ||
                        state.uri.queryParameters['from']?.startsWith(
                              '/movies',
                            ) ==
                            true
                    ? state.uri.queryParameters['from']!
                    : '/home')
              : null,
      };
    },
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const SessionSplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        name: 'start',
        builder: (context, state) => const SessionSplashScreen(),
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
                path: 'profile/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  return const SessionRatingsScreen();
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
    _auth.dispose();
    _publicClient.close(force: true);
    _authClient.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C5CE7);
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE4E1EC)),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
        Provider<TmdbMovieService>(
          create: (_) => widget.service ?? createService(),
        ),
        Provider<SignUpService>(
          create: (_) => widget.memberService ?? SignUpService(_publicClient),
        ),
      ],
      child: MaterialApp.router(
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

// Normal app launches always use the real TMDB API. Test doubles are injected
// explicitly by tests/capture tools, never selected through runtime flags.
TmdbMovieService createService() => TmdbMovieService(createTmdbClient());
