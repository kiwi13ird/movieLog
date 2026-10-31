# 5주차 실행·촬영 안내

## 구현한 기능
- TMDB 전용 Dio, .env 읽기, debug 모드에서만 마스킹 로그
- Popular 최대 5개, Discover ID 중복 제거 최대 30개
- Genre API 기반 다중 장르 BottomSheet, OR(|) 조건
- 장르 변경 시 목록 초기화, page 1부터 재요청
- RefreshIndicator: 현재 장르와 기존 목록 유지, 로딩 중 중복 요청 차단
- 실패 시 최근 성공 목록 복원, 취소/같은 장르 재시도 Dialog
- 카드 → 상세 → 평점 Dialog에 실제 TMDB ID를 가진 Movie 전달
- 포스터 null/이미지 오류 placeholder

## 직접 해야 할 일
1. 프로젝트 루트 .env에 TMDB_ACCESS_TOKEN=실제값 입력 (Bearer 접두사 없음).
2. 기존 flutter run 터미널에서 q로 종료 후 아래 명령으로 재실행.

```bash
flutter run -d emulator-5554
```

3. 홈 인기 영화, 영화 탭 목록/총 개수 확인.
4. 장르 버튼에서 2개 선택 후 확인. 콘솔 with_genres가 28|35 같은 OR 조건인지 확인.
5. 아래 촬영 시나리오 실행. 실제 토큰/.env/디버거의 원본 헤더는 촬영 금지.

## 실제 API 촬영
- 홈: 인기 영화 최대 5개 (스크롤하여 전체 확인).
- 영화 탭: 목록과 총 30개, page 1/2 로그.
- 장르: BottomSheet 다중 선택 → 확인 → Query와 변경된 목록.
- 전체: BottomSheet의 전체 → 확인 → with_genres가 없는 요청.
- 새로고침: 선택 장르 유지, 기존 목록 유지, 같은 조건 page 1부터 요청.
- 실패/재시도: 정상 목록 → Wi-Fi/모바일 데이터 모두 끄기 → 당겨 새로고침 → 기존 목록+Dialog → 연결 복원 → 재시도 → 성공.
- 실패/취소: 실패 재현 → 취소 → 기존 목록 유지.
- 최초 Error: 오프라인 상태에서 앱 완전 재실행 → 영화 탭 → Error 화면 → 연결 복원 후 다시 시도.
- 실패 로그: URL, 오류 종류/내용, 마스킹 Authorization. 토큰 원문 없음 확인.
- Loading은 화면 녹화 후 필요한 프레임을 캡처하면 편리함.

## 실제 API에서 재현하기 어려운 상태 (명시적 fixture)
매번 실행 중인 앱을 q로 종료하고 실행. 화면에 FIXTURE 배너가 붙는다.
아래 결과는 실제 TMDB 인증 증거와 구분해서 'fixture 검증'으로 제출.

```bash
# Empty: 홈/영화 탭의 빈 상태
flutter run -d emulator-5554 --dart-define=TMDB_FIXTURE=empty

# null 포스터(첫 카드), 실패 포스터(두 번째 카드), Loading
flutter run -d emulator-5554 --dart-define=TMDB_FIXTURE=posters

# 최초 Error (실제 네트워크 실패 로그 증거를 대신하지 않음)
flutter run -d emulator-5554 --dart-define=TMDB_FIXTURE=error
```

촬영 후에는 dart-define 없는 정상 실행으로 돌아오기.

## 검증 명령
```bash
flutter analyze
flutter test

git check-ignore .env
git ls-files .env
```
마지막 명령은 출력이 없어야 한다. 현재 추적 여부 검사이며 과거 노출 검사를 대신하지 않는다.

release 로그 검증은 실제 Android 기기에서 실행:
```bash
flutter devices
flutter run --release -d 실제기기ID
```
실제 요청은 작동하고 [TMDB 요청/응답/오류] debug 로그는 없어야 한다.
실기기 미보유 등으로 실행하지 못했으면 '미검증'으로 기록.
fixture 분기와 인터셉터 등록은 kDebugMode 조건으로 release에서 제외된다.

## 제출 양식
PR 링크:
TMDB Token 비노출 확인:
Popular 5개 화면:
Discover 최대 30개 화면과 실제 개수:
Genre API 및 with_genres 요청 증거:
Loading / Empty / Error / Success:
포스터 null·실패 처리:
movie.id 전달 위치: MovieCard onTap extra → MovieDetailScreen.movie → _showRatingDialog(Movie)
챌린지 다중 장르/새로고침/재시도/취소 영상:
flutter analyze / flutter test 결과:
트러블슈팅:
미검증 항목:

## 트러블슈팅 기록 틀
상황과 재현 순서:
호출 API:
Query parameter(Token 제외):
기대한 상태와 결과 개수:
실제 status / 응답 모양:
ViewModel 상태:
원인:
수정:
재검증:

## 참고
- https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- https://developer.themoviedb.org/reference/discover-movie
- https://pub.dev/packages/dio
