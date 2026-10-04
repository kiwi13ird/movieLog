import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movie_list_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/start_screen.dart';
import 'widgets/main_screen.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({this.initialLocation = '/', super.key});

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
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/movies',
            name: 'movies',
            builder: (context, state) => const MovieListScreen(),
            routes: [
              GoRoute(
                path: ':movieId',
                name: 'movieDetail',
                builder: (context, state) => MovieDetailScreen(
                  movieId: state.pathParameters['movieId']!,
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

    return MaterialApp.router(
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
    );
  }
}
