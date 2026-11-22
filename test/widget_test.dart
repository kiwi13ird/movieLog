import 'dart:async';

import 'package:movielog/data/models/api_failure.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/services/fixture_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/session_fixture.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('보호 경로는 저장소 확인 후 로그인으로 이동하고 뒤로가기로 우회할 수 없다', (tester) async {
    final auth = AuthViewModel(SessionFixtureApi(), MemoryTokens());
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my/profile/edit',
        auth: auth,
        service: FixtureMovieService('posters'),
      ),
    );
    expect(find.text('FLUTTER 8주차'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('MovieLog 로그인'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('MovieLog 로그인'), findsOneWidget);
  });
  testWidgets('복원 GET me 완료 전에는 보호 화면을 노출하지 않는다', (tester) async {
    final api = SessionFixtureApi()..pendingMember = Completer();
    final auth = AuthViewModel(api, MemoryTokens()..token = 'test-only');
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my',
        auth: auth,
        service: FixtureMovieService('posters'),
      ),
    );
    await tester.pump();
    expect(find.text('FLUTTER 8주차'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    api.pendingMember!.complete(member());
    await tester.pumpAndSettle();
    expect(find.text('검증회원'), findsOneWidget);
    expect(find.text('2026.10.10 가입'), findsOneWidget);
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('MovieLog 로그인'), findsOneWidget);
    expect(find.textContaining('만료됐어요'), findsNothing);
  });
  testWidgets('프로필과 평점 화면은 하단 탭을 숨기고 취소 시 마이페이지로 돌아간다', (tester) async {
    final auth = signedInFixture();
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my',
        auth: auth,
        service: FixtureMovieService('posters'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.enterText(find.byType(TextFormField).last, '바뀐닉네임');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('변경 내용을 취소할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(find.text('바뀐닉네임'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('바뀐닉네임'), findsOneWidget);
    await tester.tap(find.byKey(const Key('myRatingsTile')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.textContaining('전체 내 평점'), findsOneWidget);
  });
  testWidgets('만료 안내는 프레임 추가 입력 없이 나타나고 한 번만 소비된다', (tester) async {
    final auth = signedInFixture();
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my',
        auth: auth,
        service: FixtureMovieService('posters'),
      ),
    );
    await tester.pumpAndSettle();
    ScaffoldMessenger.of(tester.element(find.text('마이페이지')))
        .showSnackBar(const SnackBar(content: Text('이전 저장 알림')));
    await tester.pump();
    await auth.handleFailure(
      const ApiFailure('만료', code: 'AUTH401_4'),
      auth.sessionVersion,
    );
    await tester.pumpAndSettle();
    expect(find.text('MovieLog 로그인'), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(auth.consumeSessionExpired(), false);
    expect(find.text('이전 저장 알림'), findsNothing);
  });
}
