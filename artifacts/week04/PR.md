# 4주차: 비동기 영화 목록과 장르 저장·복원

기존 동기 영화 목록을 Mock Future 기반으로 변경하여 1초 Loading 이후 Success·Empty·Error 상태를 표시합니다. 오류 화면의 다시 시도는 새로운 Future를 만들고 정상 목록을 불러옵니다.

- 기존 Movie와 MovieCard 재사용
- Future를 initState에서 생성하고 상태별 Widget 분리
- SharedPreferencesAsync로 마지막 선택 장르 저장·복원 (`selected_genre`)
- 인증용 옵션에서 Success·Empty·Error·Timeout 재현
- 당겨서 새로고침과 3초 타임아웃
- 5주차 API 교체 위치에 TODO 표시

검증: flutter analyze 오류 없음, flutter test 7개 통과.

인증 캡처 및 영상은 아직 첨부하지 않았습니다.
