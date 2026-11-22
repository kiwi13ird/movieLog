# movielog

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 4주차 미션 인증

- 영화 탭 진입: 1초 Loading 이후 기존 영화 카드 목록(Success)이 표시됩니다.
- 우측 상단 옵션 → `Empty 확인`: 빈 목록 안내를 확인합니다.
- 옵션 → `Error 확인` → `다시 시도`: Error → Loading → Success 영상을 촬영합니다.
- 장르 Chip 선택 후 앱을 완전히 종료하고 다시 실행해 영화 탭에서 선택 복원을 확인합니다.
- 저장 키: `selected_genre` (`SharedPreferencesAsync`).
- Future 생성: `MovieListScreen.initState`에서 최초 생성하고, 재시도·당겨서 새로고침·Mock 상태 선택 시 갱신합니다. 장르 변경은 기존 결과만 필터링합니다.
- 추가 챌린지: 당겨서 새로고침, 3초 타임아웃, Mock 서비스 Unit Test 및 네 상태 Widget Test.
- `flutter analyze`, `flutter test`로 검증합니다.

인증 제출 시 Loading·Empty·Success 캡처, Error 재시도 및 앱 재실행 장르 복원 영상, 분석 결과와 PR 링크를 첨부하세요.

## 5주차 TMDB + Challenge

현재 앱의 홈/영화 탭은 Provider 기반 TMDB 연동을 사용합니다.
기존 4주차 Mock 메뉴/단일 장르 로컬 필터 대신 서버 조회와 다중 장르 선택을 사용합니다.
`.env.example`을 참고해 `.env`를 설정하세요. 토큰은 커밋하지 않습니다.

실행·촬영·제출 방법: [5주차 제출 안내](docs/week05-submission.md)

## 6주차 중복 확인 + 내가 등록한 평점

워크북 v5 공개 API로 닉네임·이메일 중복 확인과 학습용 memberId 1 평점 조회를 연결했습니다.
중복 문자열 재입력 시 에러 복원, 요청 응답 무효화, TMDB 상세 캐시/placeholder를 지원합니다.
계정 생성·평점 저장 요청은 보내지 않습니다.

실행·검증 모드·캡처 순서·제출 양식: [6주차 제출 안내](docs/week06-submission.md)

## 7주차 v6 회원가입·평점 CRUD + Challenge

현재 앱은 v6로 회원가입하고 성공한 memberId를 메모리 세션에 저장합니다.
영화 상세에서 정수 별점·코멘트를 등록하고, 마이페이지에서 수정·단일 삭제·다중 삭제합니다.
저장 후 GET 실패는 별도로 표시하며 조회만 재시도합니다.
이전 4~6주차 안내는 당시 구현 기록입니다.

실행·챌린지 검증 모드·촬영 순서: [7주차 제출 안내](docs/week07-submission.md)

## 현재 8주차 JWT 인증과 v7 평점

`week08` 브랜치에서 보안 토큰 저장, 로그인/복원/만료/로그아웃, 내 정보와 닉네임 수정, v7 평점 CRUD 및 챌린지를 구현했습니다.
현재 세션에서 등록한 평점만 관리하며, 전체 내 평점 재시작 복원은 서버 계약상 지원하지 않습니다.

구현·실제 API 검증·Android 보안 저장소 증거·제출 절차: [8주차 제출 안내](docs/week08-submission.md)
