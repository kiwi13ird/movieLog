import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  Future<void> enterValidSignUp(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('nicknameField')), '키위');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'kiwi@movielog.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();
  }

  testWidgets('시작-회원가입-홈 흐름과 온보딩 백스택이 올바르다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('시작하기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startButton')));
    await tester.pumpAndSettle();
    expect(find.text('반가워요!'), findsOneWidget);

    await enterValidSignUp(tester);
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤 영화를\n기록해 볼까요?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('반가워요!'), findsNothing);
    expect(find.text('시작하기'), findsNothing);
  });

  testWidgets('유효한 회원가입 정보일 때만 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(const MovieLogApp(initialLocation: '/signup'));

    FilledButton button() =>
        tester.widget<FilledButton>(find.byKey(const Key('signUpButton')));
    expect(button().onPressed, isNull);
    await enterValidSignUp(tester);
    expect(button().onPressed, isNotNull);
  });

  testWidgets('네비게이션과 장르 필터, BottomSheet가 동작한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp(initialLocation: '/home'));

    var navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('mainNavigationBar')),
    );
    expect(navigationBar.selectedIndex, 0);

    await tester.tap(find.text('영화'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    navigationBar = tester.widget(find.byKey(const Key('mainNavigationBar')));
    expect(navigationBar.selectedIndex, 1);
    expect(find.byKey(const Key('movieList')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('genre-SF')));
    await tester.pumpAndSettle();
    expect(find.text('인터스텔라'), findsOneWidget);
    expect(find.text('라라랜드'), findsNothing);

    await tester.tap(find.byKey(const Key('movieOptionsButton')));
    await tester.pumpAndSettle();
    expect(find.text('영화 보기 옵션'), findsOneWidget);
    await tester.ensureVisible(find.text('닫기'));
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    navigationBar = tester.widget(find.byKey(const Key('mainNavigationBar')));
    expect(navigationBar.selectedIndex, 2);
    expect(find.text('마이페이지'), findsOneWidget);
  });

  testWidgets('카드 ID 경로 상세, 평점, 즐겨찾기, 뒤로가기가 동작한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp(initialLocation: '/movies'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('movieCard-la-la-land')));
    await tester.pumpAndSettle();
    expect(find.text('라라랜드'), findsOneWidget);
    expect(find.byType(RatingBarIndicator), findsOneWidget);

    await tester.tap(find.byKey(const Key('favoriteButton')));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('favoriteButton')));
    await tester.pump();
    expect(find.text('즐겨찾기에서 삭제했습니다.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('openRatingDialogButton')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('openRatingDialogButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movieRatingInput')), findsOneWidget);
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('movieRatingInput'))) +
          const Offset(19, 0),
    );
    await tester.pump();
    expect(find.textContaining('/ 5.0'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detailBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movieList')), findsOneWidget);
  });
}
