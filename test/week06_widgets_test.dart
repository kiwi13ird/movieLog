import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/services/week06_fixture_services.dart';
import 'package:movielog/widgets/movielog_button.dart';

MovieLogApp fixtureApp(
  String route, {
  String mode = 'success',
  FixtureSignUpService? checks,
  Duration delay = Duration.zero,
}) => MovieLogApp(
  key: UniqueKey(),
  session: LearningMemberSession()
    ..setMember(
      const SignUpResult(
        memberId: 9001,
        email: 'fixture@example.com',
        nickname: '검증회원',
      ),
    ),
  initialLocation: route,
  service: Week06FixtureMovieService(mode),
  memberService: checks ?? FixtureSignUpService(delay: delay),
  ratingService: FixtureRatingApiService(mode, delay: delay),
);
void main() {
  testWidgets(
    'signup loading, duplicate error, invalidation and duplicate restoration use the field state',
    (tester) async {
      final checks = FixtureSignUpService();
      await tester.pumpWidget(fixtureApp('/signup', checks: checks));
      MovieLogButton button(String key) =>
          tester.widget<MovieLogButton>(find.byKey(Key(key)));
      expect(button('checkNicknameButton').onPressed, isNull);
      await tester.enterText(find.byKey(const Key('nicknameField')), '수현');
      await tester.pump();
      await tester.tap(find.byKey(const Key('checkNicknameButton')));
      await tester.pump();
      expect(button('checkNicknameButton').isLoading, isTrue);
      expect(
        find.descendant(
          of: find.byKey(const Key('checkNicknameButton')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(button('checkNicknameButton').onPressed, isNull);
      final field = find.descendant(
        of: find.byKey(const Key('nicknameField')),
        matching: find.byType(TextFormField),
      );
      expect(tester.state<FormFieldState<String>>(field).hasError, isTrue);
      await tester.enterText(find.byKey(const Key('nicknameField')), '새닉네임');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      expect(button('checkNicknameButton').onPressed, isNotNull);
      await tester.enterText(find.byKey(const Key('nicknameField')), '수현');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(button('checkNicknameButton').onPressed, isNull);
      expect(checks.nicknameRequests, ['수현']);
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'noco@umc.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('checkEmailButton')));
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'new@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'noco@umc.com',
      );
      await tester.pump();
      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      expect(checks.emailRequests, ['noco@umc.com']);
    },
  );
  testWidgets(
    'signup works on a narrow screen and both confirmations gate the full-width button',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(fixtureApp('/signup'));
      await tester.enterText(find.byKey(const Key('nicknameField')), '새닉네임');
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'new@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'Valid123!',
      );
      await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
      await tester.tap(find.byKey(const Key('termsCheckbox')));
      await tester.pump();
      MovieLogButton submit() =>
          tester.widget<MovieLogButton>(find.byKey(const Key('signUpButton')));
      expect(submit().onPressed, isNull);
      await tester.ensureVisible(find.byKey(const Key('checkNicknameButton')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('checkNicknameButton')));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.tap(find.byKey(const Key('checkEmailButton')));
      await tester.pumpAndSettle();
      expect(submit().onPressed, isNotNull);
      expect(submit().width, double.infinity);
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);
      expect(find.text('사용할 수 있는 이메일입니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ratings child hides navigation bar; back restores MyPage', (
    tester,
  ) async {
    await tester.pumpWidget(fixtureApp('/my'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('myRatingsTile')));
    await tester.pumpAndSettle();
    expect(find.text('학습용 회원 #9001의 평점 · 로그인 인증 전 단계'), findsOneWidget);
    expect(find.byKey(const Key('ratingsSuccess')), findsOneWidget);
    expect(find.text('포레스트 검프'), findsOneWidget);
    expect(find.text('null'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byKey(const Key('ratingsBackButton')));
    await tester.pumpAndSettle();
    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
  testWidgets(
    'ratings loading, empty, failure and missing movie metadata have distinct screens',
    (tester) async {
      for (final mode in ['empty', 'error', 'tmdb-error']) {
        await tester.pumpWidget(
          fixtureApp(
            '/my/ratings',
            mode: mode,
            delay: const Duration(milliseconds: 800),
          ),
        );
        expect(find.byKey(const Key('ratingsLoading')), findsOneWidget);
        await tester.pumpAndSettle();
        if (mode == 'empty') {
          expect(find.byKey(const Key('ratingsEmpty')), findsOneWidget);
        } else if (mode == 'error') {
          expect(find.byKey(const Key('ratingsError')), findsOneWidget);
          expect(find.text('다시 시도'), findsOneWidget);
        } else {
          expect(find.byKey(const Key('ratingsSuccess')), findsOneWidget);
          expect(find.text('영화 정보를 불러올 수 없어요'), findsWidgets);
          expect(find.text('최고의 영화!'), findsOneWidget);
          expect(find.text('★ 5 / 5'), findsOneWidget);
        }
      }
    },
  );
  testWidgets('MovieLogButton widths and loading/disabled callback behavior', (
    tester,
  ) async {
    await tester.pumpWidget(fixtureApp('/button-showcase'));
    final intrinsic = tester
        .getSize(find.byKey(const Key('buttonWidthNull')))
        .width;
    final fixed = tester
        .getSize(find.byKey(const Key('buttonWidthFixed')))
        .width;
    final full = tester.getSize(find.byKey(const Key('buttonWidthFull'))).width;
    expect(fixed, 160);
    expect(intrinsic, lessThan(fixed));
    expect(full, greaterThan(fixed));
    var clicks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MovieLogButton(
            label: '실행',
            isLoading: true,
            onPressed: () => clicks++,
          ),
        ),
      ),
    );
    expect(find.text('실행'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(clicks, 0);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: MovieLogButton(label: '실행', onPressed: null)),
      ),
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
}
