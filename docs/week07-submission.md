# 7주차 제출 안내 · v6 회원가입·평점 CRUD + Challenge

## 브랜치

- 6주차 구현은 PR #7로 main 병합 완료: https://github.com/kiwi13ird/movieLog/pull/7
- 7주차 작업 브랜치: `Week07` (6주차가 반영된 main에서 생성)
- 7주차 PR: https://github.com/kiwi13ird/movieLog/pull/8 (병합하지 않음)
- 위 PR #7은 **6주차 PR**입니다. 7주차 제출 시에는 Week07의 새 PR 링크를 사용하세요.

## 이번 구현

- SignUpService로 이름 변경, 닉네임/이메일 GET을 /v6로 변경.
- 실제 회원가입 POST, 강한 비밀번호 검사, 최종 409와 비밀번호 400 문구 구분.
- LearningMemberSession에 성공 result의 memberId/닉네임/이메일만 메모리로 보관.
- 영화 상세의 정수 별점 + 선택 코멘트(500자) Dialog에서 평점 POST.
- 마이페이지의 현재 학습용 회원 평점 GET, 수정 PATCH, 삭제 DELETE.
- PATCH는 score와 comment를 명시적으로 전송. 코멘트를 지우면 null 전송.
- DELETE 204는 body를 JSON 객체로 캐스팅하지 않음.
- 저장 실패 시 Dialog와 입력 유지. 저장 성공 후 GET 실패는 별도 배너와 GET 전용 재시도.
- Signup/평점 저장 중 뒤로가기·중복 탭 차단.
- 다중 선택 모드, 선택 개수, 취소, 선택 삭제 확인, 오버레이, 일부 실패 항목 유지.
- TMDB Client와 MovieLog Client 분리. MovieLog 요청에는 TMDB 인증 헤더가 없음.

## 실제 서버 실행과 촬영

에뮬레이터를 켠 다음 (기기 ID가 다르면 변경):

```bash
flutter run -d emulator-5554
```

이전 실행이 남아 있으면 해당 터미널에서 q로 종료하고 실행하세요.
워크북 서버 https://workbook.devnoco.com 의 **v6 API**를 사용하므로 로컬 Docker는 필요하지 않습니다.

1. 시작하기 → 회원가입. 본인만 사용할 별도 테스트 이메일·닉네임을 입력.
2. 비밀번호는 8자 이상, 대문자·소문자·숫자·!@#$%^&* 중 특수문자를 모두 포함.
3. 닉네임·이메일 중복 확인을 각각 완료하고 약관 체크.
4. 가입하기 → 실제 성공하면 영화 목록으로 이동. 성공 Snackbar의 학습용 회원 ID 확인.
5. 영화 선택 → 상세 화면에 TMDB 영화 ID와 학습용 회원 ID 확인.
6. 평점 남기기 → 별 선택 전 확인 비활성, 별을 정수로 선택하고 코멘트 입력 → 확인.
7. 같은 상세 화면의 등록 성공 Snackbar 촬영.
8. 마이 → 내가 등록한 평점 → 새로 등록한 영화 ID·점수·코멘트 확인.
9. 수정 → 기존 별점·코멘트가 채워진 Dialog 확인 → 수정 → 목록 갱신.
10. 삭제 → 취소하면 항목 유지. 다시 삭제 → 확인하면 삭제·목록 갱신. 마지막 항목이면 Empty.
11. 여러 평점을 만든 뒤 상단 편집 → 카드 선택 → 선택한 N개 삭제 → 확인 후 오버레이와 결과 촬영.

**현재 회원은 메모리 상태이며 인증/로그인이 아닙니다.** 앱을 완전히 재시작하면 사라집니다.
실제 흐름 촬영은 가입부터 CRUD까지 한 번의 실행에서 진행하세요.
고정 memberId 1이나 임의의 타인 ID를 입력해 편집하는 UI는 없습니다.

비밀번호는 로그·파일·SharedPreferences에 저장하지 않습니다. 촬영 중에도 비밀번호 표시 버튼을 누르지 마세요.
.env, 디버거의 요청 body, 실제 비밀번호가 보이는 화면은 촬영하지 않습니다.

## 재현 가능한 debug fixture 촬영

아래는 기기 안의 메모리 API 에뮬레이터를 사용합니다. **FIXTURE 배너**가 표시되고 실제 서버 데이터는 변경하지 않습니다.
제출 자료에 반드시 'fixture로 검증'이라고 표시하고 실제 서버 인증과 구분하세요.
fixture 회원 ID 9001은 실제 본인 계정이 아닙니다.
영화 제목·포스터는 실제 TMDB에서 가져옵니다. .env의 TMDB_ACCESS_TOKEN과 인터넷 연결을 유지하세요.
각 실행 사이에는 q로 종료합니다. debug 옵션은 release에서 제외됩니다.

### 기본 CRUD + 다중 삭제

```bash
flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=success --dart-define=START_ROUTE=/my/ratings
```

평점 3개가 준비되어 있습니다.
- 수정 버튼 → 기존 score/comment 초기값 확인. 후기 지우기 → 저장 → null 반영 확인.
- 단일 삭제: 확인창을 유지한 채 로딩 → 목록 갱신.
- 편집 → 선택 → 취소: 요청 없이 선택 해제.
- 편집 → 선택 → 선택한 N개 삭제 → 삭제: 확인창은 닫히고 화면에 로딩 오버레이.
- 아무것도 선택하지 않으면 하단 삭제 버튼 비활성.
- 전부 삭제하면 Empty.

### 일부 삭제 실패

```bash
flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=partial-delete --dart-define=START_ROUTE=/my/ratings
```

ratingId 2가 삭제 실패하도록 되어 있습니다. ID 1·2·3을 선택해 삭제하면 성공한 카드만 없어지고,
실패한 2번 카드가 선택된 채 남으며 'N개 삭제 실패' Snackbar가 표시됩니다.
실패한 항목만 재시도하는 로직도 자동 테스트로 검증합니다.

### 저장 성공 후 GET 실패 (중복 쓰기 방지)

```bash
flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=refresh-error --dart-define=START_ROUTE=/my/ratings
```

첫 수정 또는 삭제를 진행하면 쓰기는 성공하고 다음 GET 1회만 실패합니다.
Dialog가 닫히고 저장 완료/목록 재조회 실패 안내가 표시되어야 합니다.
**'목록 조회만 다시 시도'**를 누르면 GET만 다시 실행하고 복구됩니다.
자동 테스트가 PATCH/DELETE 요청이 늘지 않는 것까지 검사합니다.

### 저장 실패와 입력 보존

```bash
flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=write-error --dart-define=START_ROUTE=/my/ratings
```

수정 Dialog에서 코멘트를 바꾸고 확인 → 오류 문구와 기존 입력이 유지되는 장면 촬영.
저장 중에는 TextField와 별점이 비활성이고 시스템 뒤로가기로 닫히지 않습니다.

### 최종 가입 409 / 비밀번호 서버 400

```bash
flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=signup-409 --dart-define=START_ROUTE=/signup

flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=password-400 --dart-define=START_ROUTE=/signup
```

`수현` / `noco@umc.com`은 fixture 중복 확인에서 중복입니다.
그 밖의 유효한 닉네임·이메일로 중복 확인 후 비밀번호·약관까지 채워 제출합니다.
- signup-409: GET은 사용 가능이어도 최종 POST에서 409 → Snackbar, 입력 유지.
- password-400: 로컬 검증 통과 후 서버가 비밀번호 오류를 반환 → 비밀번호 필드 오류.
- 가입하기 진행 중 Android 뒤로가기를 시도해 화면이 유지되는 장면 촬영.

### Empty

```bash
flutter run -d emulator-5554 --dart-define=WEEK07_FIXTURE=empty --dart-define=START_ROUTE=/my/ratings
```

정상 실행으로 돌아올 때는 q로 종료한 뒤 `flutter run -d emulator-5554`로 실행합니다.

## 인증 목록

| 항목 | 자료 |
|---|---|
| 가입 | 실제 성공 회원 ID + 최종 409(필요 시 fixture) |
| 입력 | 확인 결과 무효화, 비밀번호 조건, 서버 400 구분 |
| 등록 | 상세 TMDB ID → 정수 별/코멘트 → 성공 Snackbar → 내 목록 |
| 수정 | 기존 값이 채워진 Dialog → PATCH → 목록 |
| 단일 삭제 | 취소·삭제 중 Dialog 유지·성공·마지막 Empty |
| 입력 보존 | 저장 실패해도 별점·코멘트 유지 |
| GET 전용 복구 | 쓰기 성공 후 조회 실패 → 조회만 재시도 |
| Challenge | 편집/선택 수/취소/선택 삭제/오버레이/이탈 방지/부분 실패 |
| 코드·검사 | 공통 응답/204 분기, flutter analyze, flutter test |

Mac 영역 캡처: Command+Shift+4. 영상: Command+Shift+5.

## 검사

```bash
flutter analyze
flutter test
flutter build apk --debug

# 실제 Swagger 명세만 읽어 Method·성공 상태코드 확인. 회원/평점은 변경하지 않음.
dart run tool/verify_week07_contract.dart
```

실제 서버 확인 범위는 공개 Swagger의 v6 계약 읽기입니다.
실제 본인 계정 생성·원격 평점 CRUD와 기기 오프라인 복구는 수동 촬영 단계에서 검증해야 합니다.
자동 테스트의 fixture 성공을 실제 서버 쓰기 성공으로 기록하지 마세요.

## 제출 양식

PR 링크: https://github.com/kiwi13ird/movieLog/pull/8
생성한 본인 테스트 계정(비밀번호 제외):
닉네임/이메일 확인과 입력 변경 무효화:
회원가입 결과와 최종 409:
선택한 TMDB id → MovieLog movieId 증거:
등록→조회→수정→조회→삭제→조회 증거:
오류 code 처리 증거:
저장 성공/재조회 실패 분리 증거:
다중 선택·삭제·부분 실패:
fixture로 검증한 항목:
트러블슈팅:
미검증 항목:

## 트러블슈팅 기록 틀

작업: 회원가입 / 등록 / 조회 / 수정 / 삭제
요청 Method·Path(비밀번호 제거):
요청 body(민감 정보 제거):
기대 status·body:
실제 status·code·message:
화면 상태:
원인과 수정:
재검증:

## 생성된 제출 이미지

`artifacts/week07/captures/README.md`에 노션 첨부 순서가 있습니다. PNG 25장 중 01–22는 실제 앱 위젯과 재현용 API로 만든 화면이며, 23–25는 실제 검사 로그·검증 범위·PR 정보를 정리한 이미지입니다. 실제 서버 쓰기나 기기 수동 검증을 완료한 자료는 아닙니다.

`artifacts/week07/captures/gallery.html`을 열면 전체 이미지를 볼 수 있습니다. Mac의 AppleSDGothicNeo 글꼴을 사용한 opt-in 렌더링 도구는 다음과 같이 실행합니다. `support/`에는 캡처에 사용한 공개 TMDB 메타데이터와 포스터만 있으며 인증 값은 없습니다.

```bash
flutter analyze > artifacts/week07/captures/flutter-analyze.txt 2>&1
flutter test --reporter expanded > artifacts/week07/captures/flutter-test.txt 2>&1
flutter test tool/capture_week07.dart --dart-define=WEEK07_FIXTURE=success
```
