import 'package:dio/dio.dart';

import '../models/api_failure.dart';
import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  SignUpService(this.dio);
  final Dio dio;
  Future<bool> checkNickname(String nickname) => _check('nickname', nickname);
  Future<bool> checkEmail(String email) => _check('email', email);
  Future<bool> _check(String field, String value) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/v6/members/$field/${Uri.encodeComponent(value.trim())}',
    );
    return CheckResult.fromJson(response.data!).available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/v6/members',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw const ApiFailure('가입 결과를 확인하지 못했습니다. 다시 요청하기 전에 서버 상태를 확인해 주세요.');
    }
    final result = CommonResponse<SignUpResult>.fromJson(
      response.data!,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
    if (!result.isSuccess) throw ApiFailure(result.message, code: result.code);
    return result;
  }
}
