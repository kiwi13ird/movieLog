import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Debug/test-only API emulator. One instance holds one app's in-memory data.
class Week07FixtureAdapter implements HttpClientAdapter {
  Week07FixtureAdapter(
    this.mode, {
    this.delay = const Duration(milliseconds: 900),
  });
  final String mode;
  final Duration delay;
  final List<RequestOptions> requests = [];
  final Map<int, Map<String, dynamic>> ratings = {};
  int _nextId = 10;
  bool _wrote = false;
  bool failWrites = false;
  bool failReads = false;
  int? failDeleteId;
  bool _refreshFailedOnce = false;
  bool registered = false;
  ResponseBody _body(int status, Object? data) => ResponseBody.fromString(
    data == null ? '' : jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  Map<String, dynamic> _common(
    bool ok,
    int status,
    String message, [
    Object? result,
  ]) => {
    'isSuccess': ok,
    'code': 'COMMON$status',
    'message': message,
    'result': result,
  };
  void seed() {
    for (final entry in [(1, 550), (2, 680), (3, 13)]) {
      ratings[entry.$1] = {
        'ratingId': entry.$1,
        'movieId': entry.$2,
        'score': entry.$1 + 2,
        'comment': entry.$1 == 3 ? null : '학습용 코멘트 ${entry.$1}',
        'createdAt': '2026-11-15T00:00:00.000Z',
        'updatedAt': '2026-11-15T00:00:00.000Z',
      };
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      o.copyWith(
        data: o.data is Map && (o.data as Map).containsKey('password')
            ? {...o.data as Map, 'password': '***'}
            : o.data,
      ),
    );
    await Future<void>.delayed(delay);
    final path = o.uri.path;
    final data = o.data is Map
        ? Map<String, dynamic>.from(o.data as Map)
        : <String, dynamic>{};
    if (path.contains('/nickname/') || path.contains('/email/')) {
      final value = o.uri.pathSegments.last;
      return _body(200, {
        'available': value != '수현' && value != 'noco@umc.com',
      });
    }
    if (path == '/v6/members' && o.method == 'POST') {
      if (mode == 'signup-409' || registered) {
        return _body(409, _common(false, 409, '이미 사용 중인 이메일입니다.'));
      }
      if (mode == 'password-400') {
        return _body(400, _common(false, 400, '비밀번호 형식을 다시 확인해 주세요.'));
      }
      registered = true;
      return _body(
        201,
        _common(true, 201, '회원가입에 성공했습니다.', {
          'memberId': 9001,
          'email': data['email'],
          'nickname': data['nickname'],
        }),
      );
    }
    if (o.method == 'GET' && path.endsWith('/ratings')) {
      if (failReads ||
          (mode == 'refresh-error' && _wrote && !_refreshFailedOnce)) {
        _refreshFailedOnce = true;
        return _body(503, _common(false, 503, '목록 조회에 실패했습니다.'));
      }
      final values = ratings.values.toList()
        ..sort(
          (a, b) => (b['ratingId'] as int).compareTo(a['ratingId'] as int),
        );
      return _body(200, values);
    }
    if (failWrites || mode == 'write-error') {
      return _body(
        400,
        _common(false, 400, '저장하지 못했습니다. 입력을 유지하고 다시 시도해 주세요.'),
      );
    }
    if (o.method == 'POST') {
      if (ratings.values.any((r) => r['movieId'] == data['movieId'])) {
        return _body(409, _common(false, 409, '이미 이 영화에 평점을 남기셨습니다.'));
      }
      final id = _nextId++;
      ratings[id] = {
        ...data,
        'ratingId': id,
        'comment': data['comment'],
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      _wrote = true;
      return _body(201, _common(true, 201, '등록되었습니다.', id));
    }
    final id = int.tryParse(o.uri.pathSegments.last);
    if (id == null || !ratings.containsKey(id)) {
      return _body(404, _common(false, 404, '존재하지 않는 평점입니다.'));
    }
    if (o.method == 'PATCH') {
      ratings[id] = {
        ...ratings[id]!,
        'score': data['score'],
        'comment': data['comment'],
      };
      _wrote = true;
      return _body(200, _common(true, 200, '수정되었습니다.'));
    }
    if (o.method == 'DELETE') {
      if (id == failDeleteId || (mode == 'partial-delete' && id == 2)) {
        return _body(403, _common(false, 403, '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.'));
      }
      ratings.remove(id);
      _wrote = true;
      return _body(204, null);
    }
    return _body(404, _common(false, 404, '경로를 확인해 주세요.'));
  }

  @override
  void close({bool force = false}) {}
}
