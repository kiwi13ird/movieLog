import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/services/fixture_movie_service.dart';

void main() {
  testWidgets(
    'failed refresh keeps cards; cancel and retry recover with same genres',
    (tester) async {
      final service = FixtureMovieService('posters');
      await tester.pumpWidget(
        MovieLogApp(initialLocation: '/movies', service: service),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('movieOptionsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('genre-28')));
      await tester.tap(find.byKey(const ValueKey('genre-35')));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      service.fail = true;
      await tester.drag(
        find.byKey(const Key('movieList')),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.byKey(const ValueKey('movieCard-1')), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('총 30개'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('movieList')),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      service.fail = false;
      service.requests.clear();
      await tester.tap(find.text('재시도'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(service.requests.first.page, 1);
      expect(service.requests.first.genres, [28, 35]);
      expect(find.text('총 30개'), findsOneWidget);
    },
  );
}
