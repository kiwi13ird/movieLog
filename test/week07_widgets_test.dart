import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/week06_fixture_services.dart';
import 'package:movielog/data/services/week07_fixture_adapter.dart';
import 'package:movielog/main.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

MovieLogApp app(
  Week07FixtureAdapter adapter, {
  String route = '/my/ratings',
  bool member = true,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
    ..httpClientAdapter = adapter;
  final session = LearningMemberSession();
  if (member) {
    session.setMember(
      const SignUpResult(
        memberId: 9001,
        email: 'fixture@example.com',
        nickname: '검증회원',
      ),
    );
  }
  return MovieLogApp(
    key: UniqueKey(),
    initialLocation: route,
    session: session,
    memberService: SignUpService(dio),
    ratingService: RatingApiService(dio),
    service: Week06FixtureMovieService('success'),
  );
}

Future<void> fillSignup(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('nicknameField')), '새닉네임');
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'new@example.com',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('checkNicknameButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('checkEmailButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('passwordField')), 'Valid123!');
  await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
  await tester.tap(find.byKey(const Key('termsCheckbox')));
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('signUpButton')));
}

void main() {
  testWidgets(
    'signup blocks back while submitting and final 409 preserves input',
    (tester) async {
      final adapter = Week07FixtureAdapter(
        'signup-409',
        delay: const Duration(milliseconds: 900),
      );
      await tester.pumpWidget(app(adapter, route: '/', member: false));
      await tester.tap(find.byKey(const Key('startButton')));
      await tester.pumpAndSettle();
      await fillSignup(tester);
      await tester.tap(find.byKey(const Key('signUpButton')));
      await tester.pump();
      expect(
        tester
            .widget<MovieLogButton>(find.byKey(const Key('signUpButton')))
            .isLoading,
        isTrue,
      );
      expect(
        tester.widget<PopScope>(find.byType(PopScope).first).canPop,
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('반가워요!'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: find.byKey(const Key('emailField')),
                matching: find.byType(TextFormField),
              ),
            )
            .controller!
            .text,
        'new@example.com',
      );
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    },
  );
  testWidgets('unregistered member cannot see editable sample account data', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(Week07FixtureAdapter('success', delay: Duration.zero), member: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
    expect(find.byKey(const Key('ratingsEditModeButton')), findsNothing);
  });
  testWidgets(
    'comment requires integer star; write failure preserves text and can retry',
    (tester) async {
      var fail = true;
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(
                    onSubmit: (score, comment) async {
                      writes++;
                      expect(score, inInclusiveRange(1, 5));
                      expect(comment, '남겨둔 코멘트');
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                      if (fail) throw StateError('failure');
                    },
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ratingCommentField')),
        '남겨둔 코멘트',
      );
      expect(
        tester
            .widget<MovieLogButton>(
              find.byKey(const Key('ratingConfirmButton')),
            )
            .onPressed,
        isNull,
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('movieRatingInput'))),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('ratingConfirmButton')));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ratingCommentField')))
            .enabled,
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ratingCommentField')))
            .controller!
            .text,
        '남겨둔 코멘트',
      );
      fail = false;
      await tester.tap(find.byKey(const Key('ratingConfirmButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(writes, 2);
    },
  );
  testWidgets(
    'single delete cancel has zero requests; deleting keeps dialog and final empty updates',
    (tester) async {
      final adapter = Week07FixtureAdapter(
        'success',
        delay: const Duration(milliseconds: 600),
      )..seed();
      adapter.ratings.remove(2);
      adapter.ratings.remove(3);
      await tester.pumpWidget(app(adapter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-rating-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
      await tester.tap(find.byKey(const ValueKey('delete-rating-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteConfirmButton')));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('ratingsEmpty')), findsOneWidget);
    },
  );
  testWidgets(
    'edit dialog prefills score/comment; refresh failure closes dialog and GET retry does not PATCH again',
    (tester) async {
      final adapter = Week07FixtureAdapter(
        'refresh-error',
        delay: Duration.zero,
      )..seed();
      await tester.pumpWidget(app(adapter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-rating-2')));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5.0'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ratingCommentField')))
            .controller!
            .text,
        '학습용 코멘트 2',
      );
      await tester.enterText(find.byKey(const Key('ratingCommentField')), '');
      await tester.tap(find.byKey(const Key('ratingConfirmButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('ratingsRefreshError')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ratingsGetRetryButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ratingsRefreshError')), findsNothing);
      expect(adapter.requests.where((r) => r.method == 'PATCH').length, 1);
      expect(
        adapter.requests.firstWhere((r) => r.method == 'PATCH').data['comment'],
        isNull,
      );
    },
  );
  testWidgets(
    'bulk deletes close confirmation before requests; overlay blocks exit; failed selection remains',
    (tester) async {
      final adapter = Week07FixtureAdapter(
        'partial-delete',
        delay: const Duration(milliseconds: 500),
      )..seed();
      await tester.pumpWidget(app(adapter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ratingsEditModeButton')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MovieLogButton>(find.byKey(const Key('bulkDeleteButton')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('select-rating-1')));
      await tester.tap(find.byKey(const ValueKey('select-rating-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('bulkDeleteButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bulkDeleteConfirmButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('ratingsWriteOverlay')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const Key('ratingsWriteOverlay')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('rating-1')), findsNothing);
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('select-rating-2')))
            .value,
        isTrue,
      );
      expect(find.textContaining('1개 삭제 실패'), findsOneWidget);
    },
  );
}
