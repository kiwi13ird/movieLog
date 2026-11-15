import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/sign_up_service.dart';
import '../data/models/sign_up_models.dart';
import '../data/models/submit_status.dart';
import '../data/models/api_failure.dart';
export '../data/models/submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class _CheckField {
  String value = '';
  String? duplicatedValue;
  CheckStatus status = CheckStatus.idle;
  String? error;
  int version = 0;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;
  SubmitStatus submitStatus = SubmitStatus.idle;
  SignUpResult? createdMember;
  int? get createdMemberId => createdMember?.memberId;
  String? passwordErrorText;
  String? snackbarMessage;
  bool get isSubmitting => submitStatus == SubmitStatus.submitting;
  final _nickname = _CheckField();
  final _email = _CheckField();
  bool _disposed = false;
  bool _validPassword = false;
  bool agreedToTerms = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;
  bool get canCheckNickname =>
      nicknameValidation(_nickname.value) == null && _canCheck(_nickname);
  bool get canCheckEmail =>
      emailValidation(_email.value) == null && _canCheck(_email);
  bool get canSubmit =>
      !isSubmitting &&
      _validPassword &&
      agreedToTerms &&
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  static String? nicknameValidation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '닉네임을 입력해 주세요.';
    if (text.length < 2 || text.length > 12) return '닉네임은 2~12자로 입력해 주세요.';
    return null;
  }

  static String? emailValidation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '이메일을 입력해 주세요.';
    if (text.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return '올바른 이메일 형식으로 입력해 주세요.';
    }
    return null;
  }

  bool _canCheck(_CheckField field) =>
      !_disposed &&
      !isSubmitting &&
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;
  void onNicknameChanged(String value) => _change(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _change(_email, value, '이메일');
  void _change(_CheckField field, String value, String label) {
    if (_disposed || isSubmitting) return;
    snackbarMessage = null;
    passwordErrorText = null;
    field.value = value.trim();
    field.version++;
    final duplicate = field.duplicatedValue == field.value;
    field.status = duplicate ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicate ? '이미 사용 중인 $label입니다.' : null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    if (_disposed) return;
    if (isSubmitting) return;
    passwordErrorText = null;
    snackbarMessage = null;
    _validPassword = passwordValidation(value) == null;
    notifyListeners();
  }

  void onTermsChanged(bool value) {
    if (_disposed) return;
    agreedToTerms = value;
    notifyListeners();
  }

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, '닉네임', canCheckNickname, _service.checkNickname);
  Future<void> checkEmail(String value) =>
      _check(_email, value, '이메일', canCheckEmail, _service.checkEmail);
  Future<void> _check(
    _CheckField field,
    String value,
    String label,
    bool allowed,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (!allowed || requested != field.value) return;
    final version = ++field.version;
    field.status = CheckStatus.checking;
    field.error = null;
    notifyListeners();
    try {
      final available = await request(requested);
      if (_disposed || version != field.version || field.value != requested) {
        return;
      }
      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      field.error = available ? null : '이미 사용 중인 $label입니다.';
      if (!available) field.duplicatedValue = requested;
    } on DioException {
      if (_disposed || version != field.version) return;
      field.status = CheckStatus.error;
      field.error = '중복 확인에 실패했습니다. 연결을 확인하고 다시 시도해 주세요.';
    } catch (_) {
      if (_disposed || version != field.version) return;
      field.status = CheckStatus.error;
      field.error = '응답을 확인하지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == field.version) notifyListeners();
  }

  static String? passwordValidation(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return '비밀번호를 입력해 주세요.';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$')
        .hasMatch(text)) {
      return '8자 이상, 대문자·소문자·숫자·특수문자(!@#\$%^&*)를 포함해 주세요.';
    }
    return null;
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed ||
        !canSubmit ||
        request.nickname.trim() != _nickname.value ||
        request.email.trim() != _email.value ||
        passwordValidation(request.password) != null) {
      return;
    }
    submitStatus = SubmitStatus.submitting;
    createdMember = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final member = response.result;
      if (!response.isSuccess || member == null || member.memberId < 1) {
        throw const ApiFailure('가입 결과를 확인하지 못했습니다. 다시 요청하기 전에 서버 상태를 확인해 주세요.');
      }
      createdMember = member;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_disposed) return;
      final failure = ApiFailure.from(
        error,
        fallback: '가입 결과를 확인하지 못했습니다. 다시 요청하기 전에 서버 상태를 확인해 주세요.',
      );
      submitStatus = SubmitStatus.error;
      if (failure.status == 400 && failure.message.contains('비밀번호')) {
        passwordErrorText = failure.message;
      } else {
        snackbarMessage = failure.message;
      }
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}
