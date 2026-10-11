import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/widgets/movie_list_states.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('Mock 서비스 성공, 빈 목록, 실패', () async {
    const service = FakeMovieService();
    expect(await service.fetchMovies(), isNotEmpty);
    expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
    await expectLater(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });

  testWidgets('Loading, Success, Empty, Error와 재시도', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MovieListScreen())),
    );
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movieList')), findsOneWidget);

    for (final mode in ['Empty', 'Error']) {
      await tester.tap(find.byKey(const Key('movieOptionsButton')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('$mode 확인'));
      await tester.tap(find.text('$mode 확인'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        find.byType(mode == 'Empty' ? MovieListEmpty : MovieListError),
        findsOneWidget,
      );
    }
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movieList')), findsOneWidget);
  });

  testWidgets('장르 저장 후 새 화면에서 복원', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MovieListScreen())),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('genre-SF')));
    await tester.pumpAndSettle();
    expect(await GenrePreference().read(), 'SF');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MovieListScreen())),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('genre-SF')))
          .selected,
      isTrue,
    );
    expect(find.text('라라랜드'), findsNothing);
    expect(find.text('인터스텔라'), findsOneWidget);
  });
}
