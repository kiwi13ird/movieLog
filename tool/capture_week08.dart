// flutter test tool/capture_week08.dart
// These screenshots use a visibly labeled fixture, never real credentials.
import 'dart:io';

import 'package:flutter/services.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/services/fixture_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../test/support/session_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
        .readAsBytesSync();
    for (final family in [
      'Ahem',
      'Roboto',
      'sans-serif',
      '.SF UI Text',
      '.SF UI Display',
    ]) {
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
    }
    final flutterPath = (Process.runSync('which', ['flutter']).stdout as String)
        .trim();
    final sdk = File(flutterPath).resolveSymbolicLinksSync();
    final icons = File(
      '${File(sdk).parent.parent.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
  });
  testWidgets('Week08 labeled UI evidence', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final frame = GlobalKey();
    final output = Directory('artifacts/week08/captures')
      ..createSync(recursive: true);
    Future<void> open(AuthViewModel auth, String route) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: frame,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Container(
                  height: 28,
                  color: const Color(0xFF6C5CE7),
                  alignment: Alignment.center,
                  child: const Text(
                    'FIXTURE API · 실제 서버 통신 아님',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: MovieLogApp(
                    key: UniqueKey(),
                    auth: auth,
                    initialLocation: route,
                    service: FixtureMovieService('posters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${output.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    final api = SessionFixtureApi();
    final auth = AuthViewModel(api, MemoryTokens());
    await open(auth, '/login');
    await shot('01-login');
    api.error = const ApiFailure('이메일 또는 비밀번호를 확인해 주세요.', code: 'AUTH401_1');
    await tester.enterText(
      find.byType(TextFormField).first,
      'fixture@example.com',
    );
    // Invoke the VM without ever rendering a password into a screenshot.
    await auth.login('fixture@example.com', 'non-secret-fixture');
    await tester.pumpAndSettle();
    await shot('02-login-error');
    api.error = null;
    await auth.login('fixture@example.com', 'non-secret-fixture');
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await shot('03-member');
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '중복닉네임');
    api.error = const ApiFailure('이미 사용 중인 닉네임입니다.', code: 'MEMBER409_1');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    await shot('04-profile-conflict');
    api.error = null;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    await shot('05-profile-saved');
    final movies = await tester.runAsync(
      () => FixtureMovieService('posters').fetchPopular(),
    );
    await auth.createRating(movies!.results.first, 4, '현재 로그인 세션에서 작성한 후기');
    await tester.tap(find.byKey(const Key('myRatingsTile')));
    await tester.pumpAndSettle();
    await shot('06-session-rating');
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    await shot('07-prefilled-rating');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await auth.handleFailure(
      const ApiFailure('만료', code: 'AUTH401_4'),
      auth.sessionVersion,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    await shot('08-expired');
    await tester.pumpWidget(const SizedBox());
  });
}
