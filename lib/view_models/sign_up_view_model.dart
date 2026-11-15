import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

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
  final MemberCheckService _service;
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
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;
  void onNicknameChanged(String value) => _change(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _change(_email, value, '이메일');
  void _change(_CheckField field, String value, String label) {
    if (_disposed) return;
    field.value = value.trim();
    field.version++;
    final duplicate = field.duplicatedValue == field.value;
    field.status = duplicate ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicate ? '이미 사용 중인 $label입니다.' : null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    if (_disposed) return;
    _validPassword = value.length >= 8;
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

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}
