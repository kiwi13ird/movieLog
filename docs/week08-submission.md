# 8주차 JWT 인증과 v7 평점 미션

`week08` 브랜치는 로그인 JWT를 보안 저장소에 보관하고, v7 내 정보와 평점 쓰기를 사용합니다. 공개 영화 조회는 기존 TMDB Client를 유지합니다.

## 본인 계정으로 사용하기

일반 앱 실행은 실제 MovieLog·TMDB 서버를 사용합니다. FIXTURE 플래그로 전환하지 않습니다. 캡처와 통합 테스트에서만 테스트 객체를 명시적으로 주입합니다.

1. 로그인 화면의 `회원가입`을 누릅니다.
2. 이메일·닉네임 중복 확인, 비밀번호 입력, 약관 동의 후 가입합니다.
3. 가입이 완료되면 입력했던 이메일이 로그인 화면에 채워집니다. 비밀번호를 다시 입력해 로그인합니다.
4. 마이페이지에서 자신의 이메일·닉네임을 확인하고 영화 상세에서 평점을 남깁니다.
5. 앱을 종료하고 다시 열면 보안 저장소 토큰을 서버에서 검증한 뒤 로그인 상태를 복원합니다.

회원 계정과 평점은 실제 서버에 저장됩니다. 앱이 제공하는 평점 목록 범위는 아래 세션/API 한계를 따릅니다.

## 구현

- `SecureTokenStorage`: `flutter_secure_storage`로 토큰 저장·읽기·삭제. 비밀번호는 저장하지 않습니다.
- 공개 MovieLog Dio: 로그인과 기존 회원가입. 보호 Dio: `AuthInterceptor`가 HTTPS `workbook.devnoco.com:443`의 `/v7/members/me`, `/v7/ratings`, `/v7/ratings/{숫자 ID}`에만 JWT를 붙입니다. TMDB Client와 공유하지 않습니다.
- `AuthViewModel`: initializing / signedOut / authenticating / signedIn / retryRequired. 신규 로그인은 토큰 저장 후 MainScreen이 내 정보를 조회합니다. 앱 재시작은 GET me 검증 뒤 signedIn이 됩니다.
- GoRouter는 한 번 생성하며 `refreshListenable`과 redirect로 보호 화면을 차단합니다. 세션 확인 중에는 Splash, 일시적인 실패는 토큰을 보존한 재시도 화면입니다.
- 마이페이지에 이메일·닉네임·가입일, 로딩·실패·재시도, 로그아웃을 연결했습니다.
- `/my/profile/edit`는 root Navigator에 표시합니다. 이메일 읽기 전용, 닉네임 2~12자 검증, 409 입력 유지, 네트워크 오류 재시도, 변경 후 뒤로가기 확인을 지원합니다. 성공 응답을 즉시 마이페이지에 반영합니다.
- 현재 세션에서 생성한 Rating의 서버 응답을 보관하고 수정·삭제합니다. PATCH는 기존 별점과 코멘트를 미리 채우고 두 필드를 함께 보냅니다.
- 이메일 저장 체크박스는 SharedPreferences에 이메일만 보관합니다.

## v6에서 v7로 변경

| 항목 | 이전 | 현재 |
| --- | --- | --- |
| 등록 | POST /v6/members/{memberId}/ratings | POST /v7/ratings |
| 수정 | PATCH /v6/members/{memberId}/ratings/{ratingId} | PATCH /v7/ratings/{ratingId} |
| 삭제 | DELETE /v6/members/{memberId}/ratings/{ratingId} | DELETE /v7/ratings/{ratingId} |
| 사용자 식별 | memberId path | 보호 Client의 Bearer |
| 등록 | 201 wrapper | 201 wrapper의 Rating |
| 수정 | 200 wrapper | 200 wrapper의 Rating |
| 삭제 | 204, body 없음 | 200 wrapper, result null |
| 공개 회원별 조회 | v6 회원별 배열 | GET /v7/members/{memberId}/ratings 배열, 토큰 없음 |

현재 앱은 `RatingApiService(publicClient, authClient)`의 v7 쓰기를 사용합니다. `LegacyRatingApiService`, 이전 평점 ViewModel, 6·7주차 테스트는 과거 계약 회귀 검증용이며 앱 실행 경로에서 사용하지 않습니다. 7주차 캡처 도구 원본은 `tool/archive/capture_week07.dart.txt`에 보존했습니다.

## 세션과 오류

| 오류 | 처리 |
| --- | --- |
| AUTH401_1 | 로그인 폼 오류, 만료 안내 없음 |
| AUTH401_2 / 3 / 4 | 현재 세션만 정리, 로그인으로 이동, 만료 Snackbar 한 번 |
| RATING403_1 | 권한 부족 안내, 로그인 유지 |
| RATING409_1 | 중복 평점 안내, 로그인 유지 |
| MEMBER409_1 | 닉네임 필드 오류, 입력 유지 |
| RATING404_1 | 삭제된 현재 세션 평점을 제거하고 오류 안내 |
| COMMON400 | 서버 message를 폼/평점 Dialog에 표시 |
| 네트워크 실패 | 로그인 유지 또는 복원 재시도. 유효한 토큰 자동 삭제 없음 |

각 비동기 작업은 sessionVersion을 확인합니다. 로그아웃·회원 전환 후 늦은 내 정보/평점 응답과 401은 새 세션을 바꾸지 않습니다. 로그아웃은 메모리 평점·회원 정보·토큰을 정리하며, 진행 중인 토큰 쓰기가 끝난 뒤 삭제합니다. 저장소 삭제 실패는 재시도 안내를 표시하고 새 로그인을 막습니다.

회원 ID를 로그인 응답이나 JWT에서 추정하지 않습니다. v7에는 토큰 기반 전체 내 평점 GET이 없으므로 **앱 재시작 후 기존 내 평점 전체 복원은 제공하지 않습니다.** 현재 세션에서 생성한 평점만 관리합니다. 영화 정보는 TMDB movieId로 결합하며, 정보가 없으면 `영화 #{movieId}`로 표시합니다. 로그아웃해도 공개 TMDB 설정과 목록은 지우지 않습니다.

## 검증 결과

검증일: 2026-11-22, Android Medium_Phone 에뮬레이터.

- `flutter analyze`: No issues found.
- `flutter test`: 37개 통과. 공개/보호 헤더 분리, v7 성공 계약, 일시 오류 재시도, 401/403/409, 중복 만료 처리, 이전 세션 응답 무효화, 프로필 오류/반영/뒤로가기, 보호 화면 라우팅을 검증했습니다.
- Android 전체 화면 통합 테스트: 로그인 실패/성공, 프로필 409/성공, 평점 등록/수정/삭제, 메모리 세션 재생성 후 검증, 만료 안내, 로그아웃 통과. 영상은 실제 Android 화면과 저장소를 사용하지만 API는 FIXTURE입니다.
- Android native secure storage: 저장·읽기·새 인스턴스 조회·삭제 통과. **동일 APK를 재설치하지 않고 force-stop 후 다시 실행**하여 저장값 읽기와 삭제를 확인했습니다. `android-process-restart.txt`에는 서로 다른 PID의 WRITE PASS와 RESTART READ AND DELETE PASS가 있습니다.
- 실제 학습 서버 REST: 테스트 회원 생성, v7 로그인, GET/PATCH me, Rating 201 등록·200 수정·200 삭제, 중복 409, 삭제 후 404, 인증 누락/무효 401, 로그인 실패 401을 확인했습니다. 결과는 `live-api-checks.json`입니다. 테스트 평점은 삭제했으며 일회성 학습 회원은 서버에 남아 있습니다. 비밀번호·JWT는 기록하지 않았습니다.
- iOS는 Keychain entitlement만 설정했으며 실행 검증하지 않았습니다. 선택 플랫폼은 Android입니다. 재설치 flag는 선택 심화 항목으로 구현하지 않았습니다.

### 증거 파일

`artifacts/week08/`에서 확인합니다.

- `live-api-checks.json`: 실제 서버 status/code/result 타입, 비밀 값 없음.
- `flutter-analyze.txt`, `flutter-test.txt`, `android-app-build.txt`: 분석·테스트·최종 APK 빌드 결과.
- `android-process-restart.txt`, `android-storage-write.png`, `android-storage-restart.png`: 실제 Android 보안 저장소.
- `captures/01-login.png` ~ `08-expired.png`: **FIXTURE API로 재현한 앱 화면**. 실제 계정 통신 캡처로 제출하면 안 됩니다.
- `android-ui-flow.txt`, `android-fixture-flow.mp4`: **FIXTURE API + 실제 Android 저장소**를 사용한 앱 동작 검증/영상. 실제 서버 REST 증거와 구분합니다.

## 실행과 재검증

```sh
flutter pub get
flutter run -d emulator-5554
flutter analyze
flutter test
flutter test integration_test/secure_storage_test.dart -d emulator-5554
flutter test integration_test/week08_flow_test.dart -d emulator-5554
flutter test tool/capture_week08.dart
```

마지막 캡처 명령은 macOS 시스템 한글 폰트를 사용합니다. Android 통합 테스트는 테스트 기기의 MovieLog 토큰 키를 지우므로 테스트용 에뮬레이터에서 실행합니다.

실제 프로세스 재시작 검증은 `tool/secure_storage_probe.dart`를 한 번 설치한 뒤 force-stop/launch 합니다. `flutter test`를 두 번 실행하면 테스트 APK 설치 과정에서 앱 데이터가 초기화될 수 있어 영속성 검증이 되지 않습니다. 그 초기 시도의 실패 로그는 `secure-storage-restart.txt`에 남겼으며 실제 성공 증거는 `android-process-restart.txt`입니다.

## 제출 전 남은 외부 작업

- 개인 계정으로 앱에 로그인하여 실제 서버와 통신하는 로그인→프로필→평점 CRUD 영상을 촬영합니다. 현재 영상은 FIXTURE 재현입니다.
- PR: https://github.com/kiwi13ird/movieLog/pull/9 (`week08` → `Week07`, 선행 PR #8 병합 후 main으로 변경).
- 개인 Notion 미션 페이지에 구현/증거를 정리하고 UMC에 제출합니다. 이 작업에서는 외부 페이지나 제출 계정을 수정하지 않았습니다.

## 제출 양식

```text
PR 링크: https://github.com/kiwi13ird/movieLog/pull/9
로그인→GET me: live-api-checks.json + 개인 계정 앱 영상 첨부
재시작 / 로그아웃 / 만료: Android FIXTURE 동작 영상 + 개인 계정 영상 첨부
닉네임 수정: 실제 REST 검증 + FIXTURE 화면 04/05
평점 v6→v7: 위 변경 표 + 실제 REST 검증 + Android FIXTURE 영상
TMDB id 결합: Rating movieId로 세션 영화 데이터 결합, 누락 시 placeholder
401/403/409: 위 오류 표 및 자동 테스트, 실제 REST status/code 기록
보안 저장소: Android 에뮬레이터 실제 저장·프로세스 재시작·읽기·삭제 PASS
비밀 비노출: JWT/비밀번호/Authorization 원문을 로그와 캡처에 기록하지 않음
트러블슈팅: 테스트 APK 재설치로 값 초기화 → 동일 APK force-stop/launch 검증으로 변경
```

설정 근거: [flutter_secure_storage 공식 문서](https://pub.dev/packages/flutter_secure_storage). Android Auto Backup을 끄고 iOS Keychain entitlement를 추가했습니다.
