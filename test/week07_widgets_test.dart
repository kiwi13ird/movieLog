// App-level v6 scenarios were replaced by the v7 session contract in Week 8.
// v6 service/view-model regression tests remain in week07_api_test.dart and
// week07_view_models_test.dart. These cover the replacement profile behavior.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/services/fixture_movie_service.dart';

import 'support/session_fixture.dart';

void main() {
  testWidgets('닉네임 중복은 입력을 유지하고 재시도 성공 시 마이페이지에 반영된다', (tester) async {
    final auth = signedInFixture();
    final api = auth.api as SessionFixtureApi;
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
    await tester.enterText(find.byType(TextFormField).last, '중복닉네임');
    api.error = const ApiFailure('이미 사용 중인 닉네임입니다.', code: 'MEMBER409_1');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('중복닉네임'), findsOneWidget);
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(auth.member!.nickname, '검증회원');
    api.error = null;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(auth.member!.nickname, '중복닉네임');
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
