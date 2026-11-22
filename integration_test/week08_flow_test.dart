// Explicit fixture UI recording on Android, with actual native token storage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/auth/token_storage.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/services/fixture_movie_service.dart';
import 'package:movielog/main.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import '../test/support/session_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Week08 Android fixture mission flow', (tester) async {
    final storage = SecureTokenStorage();
    await storage.deleteAccessToken();
    final api = SessionFixtureApi();
    final movies = FixtureMovieService('posters');
    AuthViewModel auth = AuthViewModel(api, storage);
    Future<void> pause() async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    Future<void> open(String route) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Container(
                height: 36,
                color: const Color(0xFF6C5CE7),
                alignment: Alignment.center,
                child: const Text(
                  'FIXTURE API · 실제 서버 통신 아님',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Expanded(
                child: MovieLogApp(
                  key: UniqueKey(),
                  initialLocation: route,
                  auth: auth,
                  service: movies,
                ),
              ),
            ],
          ),
        ),
      );
      await pause();
    }

    await open('/login');
    api.error = const ApiFailure('이메일 또는 비밀번호를 확인해 주세요.', code: 'AUTH401_1');
    await auth.login('fixture@example.com', 'non-secret-fixture');
    await pause();
    api.error = null;
    await auth.login('fixture@example.com', 'non-secret-fixture');
    await pause();
    await tester.tap(find.text('마이'));
    await pause();
    await tester.tap(find.text('프로필 수정'));
    await pause();
    await tester.enterText(find.byType(TextFormField).last, '새로운닉네임');
    FocusManager.instance.primaryFocus?.unfocus();
    api.error = const ApiFailure('이미 사용 중인 닉네임입니다.', code: 'MEMBER409_1');
    await tester.tap(find.text('저장'));
    await pause();
    api.error = null;
    await tester.tap(find.text('저장'));
    await pause();
    final page = await movies.fetchPopular();
    await auth.createRating(page.results.first, 4, '현재 세션에서 등록한 후기');
    await tester.tap(find.byKey(const Key('myRatingsTile')));
    await pause();
    await tester.tap(find.text('수정'));
    await pause();
    await tester.enterText(
      find.byKey(const Key('ratingCommentField')),
      '후기를 수정했습니다.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('확인'));
    await pause();
    await tester.tap(find.text('삭제'));
    await pause();
    await tester.tap(find.byKey(const Key('deleteConfirmButton')));
    await pause();
    // Recreate all in-memory authentication state, retaining native storage.
    await tester.pumpWidget(const SizedBox());
    auth = AuthViewModel(api, SecureTokenStorage());
    await open('/my');
    expect(auth.status, AuthStatus.signedIn);
    expect(api.meCalls, greaterThanOrEqualTo(2));
    await auth.handleFailure(
      const ApiFailure('무효 토큰', code: 'AUTH401_3'),
      auth.sessionVersion,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(find.textContaining('만료됐어요'), findsOneWidget);
    await auth.login('fixture@example.com', 'non-secret-fixture');
    await pause();
    await tester.tap(find.text('마이'));
    await pause();
    await tester.tap(find.text('로그아웃'));
    await pause();
    expect(find.text('MovieLog 로그인'), findsOneWidget);
    expect(await storage.readAccessToken(), isNull);
  });
}
