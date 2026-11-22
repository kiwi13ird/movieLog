import '../models/login_models.dart';
import '../models/member_info.dart';
export '../models/member_info.dart';
import 'rating_api_service.dart';

import 'package:dio/dio.dart';

import '../models/api_failure.dart';

Map<String, dynamic> result(Response<dynamic> response, {int status = 200}) {
  final body = response.data;
  if (response.statusCode != status || body is! Map<String, dynamic>) {
    throw const ApiFailure('서버 응답 형식이 올바르지 않습니다.');
  }
  if (body['isSuccess'] != true) {
    throw ApiFailure(
      body['message'] as String? ?? '요청 실패',
      code: body['code'] as String?,
    );
  }
  return body['result'] as Map<String, dynamic>;
}

class SessionApiService {
  SessionApiService(this.publicClient, this.authClient)
    : ratings = RatingApiService(publicClient, authClient);
  final RatingApiService ratings;
  final Dio publicClient, authClient;
  Future<String> login(String email, String password) async {
    final data = result(
      await publicClient.post(
        '/v7/auth/login',
        data: LoginRequest(email: email, password: password).toJson(),
      ),
    );
    final token = LoginResult.fromJson(data).accessToken;
    if (token.isEmpty) throw const ApiFailure('로그인 토큰이 없습니다.');
    return token;
  }

  Future<MemberInfo> fetchMe() async =>
      MemberInfo.fromJson(result(await authClient.get('/v7/members/me')));
  Future<MemberInfo> updateNickname(String nickname) async =>
      MemberInfo.fromJson(
        result(
          await authClient.patch(
            '/v7/members/me',
            data: {'nickname': nickname},
          ),
        ),
      );
}
