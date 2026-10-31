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
