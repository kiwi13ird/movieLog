# Week07 이미지 25장

01–22: 실제 앱 위젯을 자동 조작해 렌더한 PNG입니다. 재현용 FIXTURE API를 사용하며 영화 제목·포스터는 실제 TMDB 데이터를 사용합니다. 실제 서버에 회원가입·평점 쓰기는 수행하지 않았습니다. 회원 9001은 가상 학습용 회원입니다.

23: 최신 flutter analyze / flutter test 실행 로그를 정리한 이미지입니다. 원본 txt 로그도 포함했습니다.
24: Guided/Required 자동 재현 범위와 아직 하지 않은 실제 서버·기기 수동 검증을 구분한 이미지입니다. 수동 검증 완료 증거로 사용하지 마세요.
25: GitHub API로 확인한 PR #8 정보를 정리한 이미지이며 GitHub 페이지 스크린샷은 아닙니다.

PR: https://github.com/kiwi13ird/movieLog/pull/8 (Week07 → main, 병합하지 않음)

## 노션에 넣는 순서

- 회원가입 성공 / 최종 409: 02, 03 (01은 제출 전 상태)
- 평점 등록 → 목록 재조회: 04 → 05 → 06 → 07
- 평점 수정 → 목록 재조회: 08 → 09
- 삭제 취소 / 삭제 성공 / 빈 목록: 10 → 11 → 12 (일부만 삭제한 목록은 13)
- 저장 실패 후 입력 보존: 14
- 저장 성공 후 GET만 실패 → GET 재시도: 15 → 16
- 상세 등록 Snackbar → 마이페이지 내 목록: 06 → 07
- 코멘트 TextField / 별점 선택에 따른 확인 활성: 04 → 05
- 기존 별점·코멘트로 수정 Dialog 열기: 08
- 삭제 확인 → 삭제 후 목록: 10 → 13
- 다중 삭제 챌린지: 17 → 18 → 19 → 20 → 21
- 회원가입 제출 중 이탈 방지: 22
- 분석 및 자동 테스트: 23
- Guided/Required 검증 범위: 24
- PR 정보: 25

## 전체 파일

- 01_signup_ready.png — 회원가입 제출 전 · 중복 확인 완료
- 02_signup_success.png — 회원가입 성공 Snackbar · 생성 회원 ID
- 03_signup_final_409.png — 최종 중복 409 · 입력 유지
- 04_create_comment_no_star.png — 코멘트 입력 · 별점 미선택 확인 비활성
- 05_create_star_comment.png — 정수 별점과 코멘트 · 확인 활성
- 06_detail_create_success.png — 영화 상세 · 평점 등록 성공 Snackbar
- 07_create_then_get.png — 등록 후 내 평점 GET 재조회
- 08_edit_prefilled.png — 기존 별점·코멘트가 채워진 수정 Dialog
- 09_edit_then_get.png — 수정 후 내 평점 GET 재조회
- 10_delete_confirmation.png — 삭제 확인 Dialog
- 11_delete_cancel_kept.png — 삭제 취소 · 기존 평점 유지
- 12_delete_success_empty.png — 마지막 평점 삭제 성공 · Empty
- 13_delete_then_get.png — 단일 삭제 성공 후 목록 갱신
- 14_write_failure_draft_kept.png — 저장 실패 · 별점과 입력 코멘트 유지
- 15_saved_get_failed.png — 저장 성공 · GET 실패 · 조회 전용 재시도
- 16_get_retry_success.png — GET만 재시도한 후 정상 목록
- 17_bulk_zero_disabled.png — 편집 모드 · 선택 0개 삭제 비활성
- 18_bulk_three_selected.png — 3개 선택 · 삭제 버튼 활성
- 19_bulk_confirmation.png — 다중 삭제 확인 Dialog
- 20_bulk_loading_overlay.png — 확인창 닫힘 · 다중 삭제 로딩 오버레이
- 21_bulk_partial_failure.png — 부분 실패 · 실패 카드 선택 유지 · Snackbar
- 22_signup_submitting.png — 회원가입 진행 중 · 뒤로가기 차단 상태
- 23_flutter_verification.png — 코드 검증 결과
- 24_guided_required_verification.png — Guided / Required 검증 범위
- 25_pull_request.png — Pull Request #8
