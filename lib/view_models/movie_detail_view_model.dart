import 'package:flutter/foundation.dart';

import '../data/models/api_failure.dart';
import '../data/models/rating_request.dart';
import '../data/models/submit_status.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.memberId, this.movie);
  final RatingApiService _service;
  final int? memberId;
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;
  bool get busy => submitStatus == SubmitStatus.submitting;
  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || busy) throw const ApiFailure('요청 처리 중입니다.');
    final id = memberId;
    if (id == null) throw const ApiFailure('먼저 학습용 회원가입을 완료해 주세요.');
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _service.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
      submitMessage = '평점이 등록되었습니다. 마이페이지에서 확인해 주세요.';
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (!_disposed) {
        submitStatus = SubmitStatus.error;
        submitMessage = failure.message;
      }
      throw failure;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
