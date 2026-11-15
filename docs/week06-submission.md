# 6주차 제출 안내 · 중복 확인과 내가 등록한 평점

## 구현 범위

워크북 공개 서버 `https://workbook.devnoco.com`의 **v5 GET API**를 사용합니다.
지난 백엔드 실습의 로컬 MySQL/Docker 서버를 켤 필요가 없습니다.
가입하기는 두 중복 확인·입력 형식·비밀번호 길이·약관 조건을 만족하면 홈으로 이동합니다.
계정 생성 POST나 평점 등록/수정/삭제 요청은 보내지 않습니다.
평점 화면은 로그인 사용자가 아닌 **학습용 memberId 1의 공개 데이터**를 표시합니다.

## 실행

Android Studio에서 에뮬레이터를 켜고 프로젝트 터미널에서 실행합니다.
기존 앱이 flutter run으로 실행 중이면 q로 종료한 뒤 다시 실행하세요.

```bash
flutter devices
flutter run -d emulator-5554
```

기기 ID가 다르면 emulator-5554를 해당 ID로 바꿉니다.
TMDB 제목·포스터를 보려면 기존 .env의 TMDB_ACCESS_TOKEN을 유지하세요.
워크북 Client와 TMDB Client는 분리되어 있어 TMDB 토큰을 v5 서버에 보내지 않습니다.

## 실제 API 인증

```bash
# 회원가입 Form으로 바로 열기 (debug 실행 편의 기능)
flutter run -d emulator-5554 --dart-define=START_ROUTE=/signup
```

1. 닉네임 2~12자와 이메일을 입력하고 각각 중복 확인.
2. 버튼 비활성/인디케이터, 응답 후 안내를 촬영.
3. 사용 가능 결과에서 입력을 변경하면 안내·체크 표시가 없어지고 가입하기도 비활성화되는지 촬영.
4. 마이페이지 → 내가 등록한 평점으로 진입.
5. memberId 1 학습 안내, 실제 영화 제목·포스터, 점수·후기·등록일 촬영.
6. 하단 NavigationBar가 가려지고 뒤로가면 마이페이지로 돌아오는 장면 촬영.

바로 마이페이지로 시작하려면:
```bash
flutter run -d emulator-5554 --dart-define=START_ROUTE=/my
```

공유 v5 데이터는 변경될 수 있습니다. 로컬 백엔드 seed의 '수현'이 이 서버에서도 중복이라는 가정은 하지 않습니다.
실제 요청 때 받은 결과를 그대로 기록하세요.

## 재현 가능한 검증 모드

아래 모드에는 **FIXTURE 배너**가 붙습니다. 실제 서버 연결 증거와 구분해
'debug fixture로 상태/동작 검증'이라고 적고 제출하세요.
각 명령 사이에는 q로 종료합니다. release에서는 이 모드를 사용하지 않습니다.

### 중복·가용·로딩·챌린지
```bash
flutter run -d emulator-5554 --dart-define=WEEK06_FIXTURE=success --dart-define=START_ROUTE=/signup
```

- 중복 닉네임: `수현`
- 중복 이메일: `noco@umc.com`
- 사용 가능 예: `새닉네임`, `new@example.com`
- 응답 대기: 약 1.2초, 그동안 버튼은 회색 비활성·중앙 인디케이터만 표시.

촬영 순서:
1. 확인 전 → 수현 입력 → 확인 → 통신 중 → 중복 안내와 비활성 버튼.
2. 다른 문자열로 변경 → 에러 해제와 버튼 활성.
3. 수현을 다시 입력 → 로딩 없이 즉시 빨간 에러·비활성 버튼.
4. 이메일에서도 같은 과정 반복.
5. 두 항목을 사용 가능한 값으로 확인 → 비밀번호 8자 이상·약관 체크 → 전체 너비 가입하기 활성.
6. 입력값 하나 변경 → 성공 안내와 가입 가능 상태 즉시 무효화.

API를 재요청하지 않는 동작은 자동 테스트에서도 요청 횟수를 확인합니다.

### 평점 네 가지 상태
```bash
# Loading → Success, null comment인 항목은 후기 영역을 생략
flutter run -d emulator-5554 --dart-define=WEEK06_FIXTURE=success --dart-define=START_ROUTE=/my/ratings

# Empty
flutter run -d emulator-5554 --dart-define=WEEK06_FIXTURE=empty --dart-define=START_ROUTE=/my/ratings

# Error + 재시도 버튼
flutter run -d emulator-5554 --dart-define=WEEK06_FIXTURE=error --dart-define=START_ROUTE=/my/ratings

# TMDB 오류여도 점수·후기·등록일·영화 ID 유지, 제목·포스터만 placeholder
flutter run -d emulator-5554 --dart-define=WEEK06_FIXTURE=tmdb-error --dart-define=START_ROUTE=/my/ratings
```

실제 통신 실패 인증은 fixture 없는 실행에서 기기 인터넷을 끄고 평점 화면에 진입해 확인합니다.
다시 연결한 후 재시도를 눌러 복구도 촬영하세요.

### 공용 버튼 너비/상태 비교
마이페이지의 debug 전용 '공용 버튼 비교'를 누르거나:
```bash
flutter run -d emulator-5554 --dart-define=START_ROUTE=/button-showcase
```

null / double.infinity / 고정 160 세 버튼과 기본/통신 중/비활성 상태를 캡처합니다.

촬영 후 정상 실행으로 돌아오기:
```bash
flutter run -d emulator-5554
```

## 인증 자료 목록

| 자료 | 촬영할 내용 |
|---|---|
| 닉네임 상태 | 확인 전 / 로딩 / 사용 가능 / 중복 |
| 이메일 상태 | 확인 전 / 로딩 / 사용 가능 / 중복 |
| 입력 무효화 | 사용 가능 확인 후 수정하면 성공 안내 제거 |
| 챌린지 | 중복 → 다른 문자열 → 중복 문자열 재입력 즉시 에러 |
| 버튼 너비 | 공용 버튼 비교 화면의 3가지 너비 |
| 평점 진입 | 마이페이지 → 평점 화면, 하단 탭 없음, 뒤로가기 |
| 평점 상태 | Loading / Empty / Error / Success |
| 예외 보존 | TMDB 실패 시에도 평점 기록 유지, null 후기는 생략 |
| 검사 결과 | flutter analyze, flutter test |

Mac 캡처: Command+Shift+4. 녹화: Command+Shift+5.
.env 파일, 토큰, 실제 비밀번호가 보이는 편집기·디버거는 촬영하지 않습니다.

## 검사 명령

```bash
flutter analyze
flutter test
flutter build apk --debug

# 실제 서버의 세 GET API와 TMDB 상세를 Service로 확인 (네트워크 필요)
dart run tool/verify_week06_api.dart
```

## 검증 결과와 한계

- 자동 테스트: 22개 통과. 중복 캐시·입력 변경·오래된 응답·dispose·TMDB 실패 보존·캐시·라우팅·너비·320px 레이아웃 포함.
- 실제 Dart Service로 v5 닉네임/이메일 GET의 boolean 응답 확인.
- memberId 1: 평점 3건, comment null 1건 확인 (검증 시점 기준).
- TMDB movieId 13/680/550 상세의 ID·제목 파싱과 poster_path 존재 확인.
- 실제 기기의 수동 촬영/오프라인 복구는 제출자가 별도로 수행.
- release 모드의 fixture 제외는 kDebugMode 분기로 구현했으며 실기기 release 실행은 미검증.

## 제출 양식

PR 링크: (아직 생성 전)
확인 전/통신 중/가능/중복 화면:
입력 변경 시 무효화 화면 또는 영상:
동일 문자열 재입력 시 즉시 에러 화면 또는 영상:
MovieLogButton 너비 비교 화면(null / double.infinity / 고정값):
내가 등록한 평점(memberId 1) Loading/Empty/Error/Success 화면:
실제 v5 API·TMDB 연결 확인:
fixture로 검증한 항목:
트러블슈팅:
6주차 회고:
미검증 항목:

## 학습 내용 정리

- v5는 결과를 직접 반환하므로 중복 확인의 available과 평점 배열을 바로 파싱한다. result 같은 wrapper를 가정하지 않는다.
- MovieLogButton은 UI 공용 위젯으로 상태와 너비만 전달받고, 요청·중복 판단은 화면별 ViewModel에서 처리한다.
- SignUpViewModel은 닉네임·이메일마다 요청 버전과 중복 값을 따로 관리한다.
- TextFormField의 decoration.errorText에 더해 forceErrorText를 연결하여 FormField 자체도 서버 오류를 유효하지 않은 상태로 취급한다.
- 평점 화면의 원본은 v5 평점이며 TMDB 메타데이터 조회 실패를 평점 조회 실패로 합치지 않는다.
- TMDB 상세는 같은 ID를 캐시하고, 일시적 네트워크 실패는 다음 load에서 다시 시도한다.

## 트러블슈팅 기록 틀

작업: 닉네임 확인 / 이메일 확인 / 내 평점 조회
요청 Method·Path:
입력값(민감 정보 제거):
기대한 상태:
실제 상태 및 응답:
원인:
수정:
재검증:

## 공식 참고

- https://api.flutter.dev/flutter/material/TextFormField-class.html
- https://api.flutter.dev/flutter/widgets/FormField/forceErrorText.html
- https://docs.flutter.dev/cookbook/forms/validation
- https://developer.themoviedb.org/reference/movie-details
