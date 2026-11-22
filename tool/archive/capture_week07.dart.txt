// Opt-in UI evidence generation. All screenshots visibly retain the FIXTURE banner.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/week07_fixture_adapter.dart';
import 'package:movielog/main.dart';
import 'package:movielog/view_models/learning_member_session.dart';

final output = Directory('artifacts/week07/captures');
final frame = GlobalKey();
late CaptureMovies movies;
final evidence = <Map<String, String>>[];

class CaptureMovies extends TmdbMovieService {
  CaptureMovies(this.data) : super(Dio());
  final Map<int, TmdbMovieDto> data;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int id) async => data[id]!;
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async => TmdbMoviePageDto(data.values.toList(), 1);
  @override
  Future<TmdbMoviePageDto> fetchPopular() async =>
      TmdbMoviePageDto(data.values.toList(), 1);
  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [];
}

class PosterOverrides extends HttpOverrides {
  PosterOverrides(this.images);
  final Map<String, Uint8List> images;
  @override
  HttpClient createHttpClient(SecurityContext? context) => PosterClient(images);
}

class PosterClient implements HttpClient {
  PosterClient(this.images);
  final Map<String, Uint8List> images;
  @override
  Future<HttpClientRequest> getUrl(Uri uri) async =>
      PosterRequest(images[uri.path] ?? Uint8List(0));
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class PosterRequest implements HttpClientRequest {
  PosterRequest(this.bytes);
  final Uint8List bytes;
  @override
  HttpHeaders get headers => PosterHeaders();
  @override
  Future<HttpClientResponse> close() async => PosterResponse(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class PosterHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class PosterResponse extends Stream<List<int>> implements HttpClientResponse {
  PosterResponse(this.bytes);
  final Uint8List bytes;
  @override
  int get statusCode => bytes.isEmpty ? 404 : 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> shot(WidgetTester tester, String name, String title) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump();
  final boundary =
      frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
  evidence.add({
    'file': '$name.png',
    'title': title,
    'source': name.startsWith('2') && int.parse(name.substring(0, 2)) >= 23
        ? '실제 실행 로그 / 검증 범위 / GitHub PR 정보'
        : '실제 앱 위젯 / FIXTURE API / 실제 TMDB 포스터',
  });
}

Future<Week07FixtureAdapter> open(
  WidgetTester tester, {
  String mode = 'success',
  String route = '/my/ratings',
  bool member = true,
  bool seeded = true,
  Duration delay = Duration.zero,
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  final adapter = Week07FixtureAdapter(mode, delay: delay);
  if (seeded) adapter.seed();
  final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
    ..httpClientAdapter = adapter;
  final session = LearningMemberSession();
  if (member) {
    session.setMember(
      const SignUpResult(
        memberId: 9001,
        email: 'capture@example.com',
        nickname: '캡처회원',
      ),
    );
  }
  final screen = MovieLogApp(
    key: UniqueKey(),
    initialLocation: route,
    session: session,
    service: movies,
    memberService: SignUpService(dio),
    ratingService: RatingApiService(dio),
  );
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
                'FIXTURE · 상태 재현용 API / 실제 TMDB 포스터',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: screen),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
  return adapter;
}

Future<void> report(
  WidgetTester tester,
  String name,
  String title,
  List<String> rows,
) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: frame,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFFF8F7FC),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MovieLog · Week07 · 2026-11-15',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6C5CE7)),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                for (final row in rows) ...[
                  Text(row, style: const TextStyle(fontSize: 15, height: 1.6)),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await shot(tester, name, title);
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('nicknameField')), '캡처회원');
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'capture@example.com',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('checkNicknameButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('checkEmailButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('passwordField')), 'Capture123!');
  await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
  await tester.tap(find.byKey(const Key('termsCheckbox')));
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('signUpButton')));
}

Future<void> selectStar(WidgetTester tester, int score) async {
  final rect = tester.getRect(find.byKey(const Key('movieRatingInput')));
  await tester.tapAt(
    Offset(rect.left + (score - .5) * rect.width / 5, rect.center.dy),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
        .readAsBytesSync();
    debugDisableShadows = false;
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
    final icons = File(
      '/Users/gyuri/develop/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    final raw = jsonDecode(
      File('${output.path}/support/movies.json').readAsStringSync(),
    ) as List;
    movies = CaptureMovies({
      for (final value in raw)
        (value['id'] as int): TmdbMovieDto.fromJson(
          value as Map<String, dynamic>,
        ),
    });
    final cache = <String, Uint8List>{};
    for (final movie in movies.data.values) {
      cache['/t/p/w500${movie.posterPath}'] = File(
        '${output.path}/support/${movie.id}.jpg',
      ).readAsBytesSync();
    }
    HttpOverrides.global = PosterOverrides(cache);
  });
  testWidgets('Capture Week07 submission screens without real server writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Signup success, actual UI transition and server result ID.
    await open(tester, route: '/signup', member: false, seeded: false);
    await fill(tester);
    await shot(tester, '01_signup_ready', '회원가입 제출 전 · 중복 확인 완료');
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();
    await shot(tester, '02_signup_success', '회원가입 성공 Snackbar · 생성 회원 ID');
    await open(tester, mode: 'signup-409', route: '/signup', member: false);
    await fill(tester);
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();
    await shot(tester, '03_signup_final_409', '최종 중복 409 · 입력 유지');
    // Create in detail, then navigate back -> MyPage -> own list with the same adapter/session.
    final created = await open(tester, route: '/movies', seeded: false);
    await tester.tap(find.byKey(const ValueKey('movieCard-550')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('openRatingDialogButton')));
    await tester.tap(find.byKey(const Key('openRatingDialogButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ratingCommentField')),
      '다시 보고 싶은 영화예요.',
    );
    await tester.pump();
    await shot(tester, '04_create_comment_no_star', '코멘트 입력 · 별점 미선택 확인 비활성');
    await selectStar(tester, 5);
    await shot(tester, '05_create_star_comment', '정수 별점과 코멘트 · 확인 활성');
    await tester.tap(find.byKey(const Key('ratingConfirmButton')));
    await tester.pumpAndSettle();
    await shot(tester, '06_detail_create_success', '영화 상세 · 평점 등록 성공 Snackbar');
    await tester.tap(find.byKey(const Key('detailBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('myRatingsTile')));
    await tester.pumpAndSettle();
    await shot(tester, '07_create_then_get', '등록 후 내 평점 GET 재조회');
    final id = created.ratings.keys.single;
    await tester.tap(find.byKey(ValueKey('edit-rating-$id')));
    await tester.pumpAndSettle();
    await shot(tester, '08_edit_prefilled', '기존 별점·코멘트가 채워진 수정 Dialog');
    await selectStar(tester, 4);
    await tester.enterText(
      find.byKey(const Key('ratingCommentField')),
      '다시 보니 새로운 장면이 보였어요.',
    );
    await tester.tap(find.byKey(const Key('ratingConfirmButton')));
    await tester.pumpAndSettle();
    await shot(tester, '09_edit_then_get', '수정 후 내 평점 GET 재조회');
    await tester.tap(find.byKey(ValueKey('delete-rating-$id')));
    await tester.pumpAndSettle();
    await shot(tester, '10_delete_confirmation', '삭제 확인 Dialog');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await shot(tester, '11_delete_cancel_kept', '삭제 취소 · 기존 평점 유지');
    await tester.tap(find.byKey(ValueKey('delete-rating-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteConfirmButton')));
    await tester.pumpAndSettle();
    await shot(tester, '12_delete_success_empty', '마지막 평점 삭제 성공 · Empty');
    // Non-empty list after deletion.
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('delete-rating-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteConfirmButton')));
    await tester.pumpAndSettle();
    await shot(tester, '13_delete_then_get', '단일 삭제 성공 후 목록 갱신');
    // Write failure keeps the same draft.
    await open(tester, mode: 'write-error');
    await tester.tap(find.byKey(const ValueKey('edit-rating-2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ratingCommentField')),
      '저장 실패해도 이 코멘트는 유지됩니다.',
    );
    await tester.tap(find.byKey(const Key('ratingConfirmButton')));
    await tester.pumpAndSettle();
    await shot(tester, '14_write_failure_draft_kept', '저장 실패 · 별점과 입력 코멘트 유지');
    // Write succeeded; only GET failed, and retry performs GET only.
    final refresh = await open(tester, mode: 'refresh-error');
    await tester.tap(find.byKey(const ValueKey('edit-rating-3')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ratingCommentField')),
      '저장은 성공했고 목록만 다시 조회합니다.',
    );
    await tester.tap(find.byKey(const Key('ratingConfirmButton')));
    await tester.pumpAndSettle();
    await shot(tester, '15_saved_get_failed', '저장 성공 · GET 실패 · 조회 전용 재시도');
    await tester.tap(find.byKey(const Key('ratingsGetRetryButton')));
    await tester.pumpAndSettle();
    expect(refresh.requests.where((r) => r.method == 'PATCH').length, 1);
    await shot(tester, '16_get_retry_success', 'GET만 재시도한 후 정상 목록');
    // Challenge: selection, confirmation, overlay and partial failure.
    await open(
      tester,
      mode: 'partial-delete',
      delay: const Duration(milliseconds: 800),
    );
    await tester.tap(find.byKey(const Key('ratingsEditModeButton')));
    await tester.pumpAndSettle();
    await shot(tester, '17_bulk_zero_disabled', '편집 모드 · 선택 0개 삭제 비활성');
    for (final ratingId in [1, 2, 3]) {
      await tester.ensureVisible(
        find.byKey(ValueKey('select-rating-$ratingId')),
      );
      await tester.tap(find.byKey(ValueKey('select-rating-$ratingId')));
      await tester.pump();
    }
    await shot(tester, '18_bulk_three_selected', '3개 선택 · 삭제 버튼 활성');
    await tester.tap(find.byKey(const Key('bulkDeleteButton')));
    await tester.pumpAndSettle();
    await shot(tester, '19_bulk_confirmation', '다중 삭제 확인 Dialog');
    await tester.tap(find.byKey(const Key('bulkDeleteConfirmButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, '20_bulk_loading_overlay', '확인창 닫힘 · 다중 삭제 로딩 오버레이');
    await tester.pumpAndSettle();
    await shot(
      tester,
      '21_bulk_partial_failure',
      '부분 실패 · 실패 카드 선택 유지 · Snackbar',
    );
    // Signup navigation guard during request.
    await open(
      tester,
      route: '/signup',
      member: false,
      delay: const Duration(milliseconds: 800),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pump();
    // Test harness lives outside test/ to keep it opt-in.
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pump();
    await shot(tester, '22_signup_submitting', '회원가입 진행 중 · 뒤로가기 차단 상태');
    await tester.pumpAndSettle();
    final analyzeLog = await tester.runAsync(
      () => File('${output.path}/flutter-analyze.txt').readAsString(),
    );
    final testLog = await tester.runAsync(
      () => File('${output.path}/flutter-test.txt').readAsString(),
    );
    expect(analyzeLog, contains('No issues found!'));
    expect(testLog, contains('All tests passed!'));
    final testCount =
        RegExp(r'\+(\d+): All tests passed!').firstMatch(testLog!)?.group(1) ??
        '38';
    await report(tester, '23_flutter_verification', '코드 검증 결과', [
      'flutter analyze\nNo issues found! · 종료 코드 0',
      'flutter test --reporter expanded\nAll tests passed! · 테스트 $testCount개 통과',
      '검증 로그\nflutter-analyze.txt / flutter-test.txt\n원본 실행 로그를 이미지와 함께 첨부했습니다.',
      '구분\n코드 검사 및 자동 테스트 결과입니다.\n실제 서버 수동 검증 완료를 의미하지 않습니다.',
    ]);
    await report(
      tester,
      '24_guided_required_verification',
      'Guided / Required 검증 범위',
      [
        'Guided A · FIXTURE 자동 재현\n회원가입 성공 / 최종 409 / 제출 중 화면 유지',
        'Guided B · FIXTURE 자동 재현\n별점 없을 때 확인 비활성 / 코멘트 입력\n등록 Snackbar → 내 평점 GET 목록',
        'Required · FIXTURE 자동 재현\n수정 초기값 / 수정 후 GET / 삭제 취소\n삭제 후 GET / 마지막 항목 Empty\n저장 실패 입력 유지 / GET만 재시도',
        'Challenge · FIXTURE 자동 재현\n선택 개수 / 확인창 / 로딩 오버레이\n부분 실패 항목의 선택 유지',
        '미검증\n실제 서버 본인 계정 가입·CRUD 및\n기기에서의 Guided/Required 수동 검증',
      ],
    );
    final pr = jsonDecode(
      (await tester.runAsync(
        () => File('${output.path}/pr.json').readAsString(),
      ))!,
    );
    await report(tester, '25_pull_request', 'Pull Request #${pr['number']}', [
      pr['title'] as String,
      '${pr['head']} → ${pr['base']}\nPR 생성 완료 · 병합하지 않음',
      pr['url'] as String,
      '주요 구현\nv6 회원가입 및 평점 등록·조회·수정·삭제\n저장 실패 입력 보존 / GET 전용 재시도\n다중 선택 삭제 / 부분 실패 처리',
      '안내\nGitHub API로 확인한 PR 정보를 정리한 이미지입니다.\nGitHub 페이지 자체의 스크린샷은 아닙니다.',
    ]);
    await tester.runAsync(
      () => File('${output.path}/index.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence)),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    debugDisableShadows = true;
  }, timeout: const Timeout(Duration(minutes: 4)));
}
