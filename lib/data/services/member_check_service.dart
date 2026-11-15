import 'package:dio/dio.dart';

import '../models/check_result.dart';

class MemberCheckService {
  MemberCheckService(this.dio);
  final Dio dio;
  Future<bool> checkNickname(String nickname) => _check('nickname', nickname);
  Future<bool> checkEmail(String email) => _check('email', email);

  Future<bool> _check(String field, String value) async {
    final encoded = Uri.encodeComponent(value.trim());
    final response = await dio.get<Map<String, dynamic>>(
      '/v5/members/$field/$encoded',
    );
    return CheckResult.fromJson(response.data!).available;
  }
}
