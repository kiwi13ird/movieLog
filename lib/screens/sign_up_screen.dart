import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!context.read<SignUpViewModel>().canSubmit ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (context, vm, child) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SignUpHeader(),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MovieLogTextFormField(
                              key: const Key('nicknameField'),
                              controller: _nicknameController,
                              focusNode: _nicknameFocusNode,
                              label: '닉네임',
                              hint: '2~12자',
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: SignUpViewModel.nicknameValidation,
                              errorText: vm.nicknameErrorText,
                              suffixIcon:
                                  vm.nicknameCheckStatus ==
                                      CheckStatus.available
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                              onChanged: vm.onNicknameChanged,
                              onFieldSubmitted: (_) =>
                                  _emailFocusNode.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: MovieLogButton(
                              key: const Key('checkNicknameButton'),
                              label: '중복 확인',
                              isLoading:
                                  vm.nicknameCheckStatus ==
                                  CheckStatus.checking,
                              onPressed: vm.canCheckNickname
                                  ? () => vm.checkNickname(
                                      _nicknameController.text,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (vm.nicknameCheckStatus == CheckStatus.available)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '사용할 수 있는 닉네임입니다.',
                            style: TextStyle(
                              color: Color(0xFF18745B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MovieLogTextFormField(
                              key: const Key('emailField'),
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              label: '이메일',
                              hint: '이메일 주소',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: SignUpViewModel.emailValidation,
                              errorText: vm.emailErrorText,
                              suffixIcon:
                                  vm.emailCheckStatus == CheckStatus.available
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                              onChanged: vm.onEmailChanged,
                              onFieldSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: MovieLogButton(
                              key: const Key('checkEmailButton'),
                              label: '중복 확인',
                              isLoading:
                                  vm.emailCheckStatus == CheckStatus.checking,
                              onPressed: vm.canCheckEmail
                                  ? () => vm.checkEmail(_emailController.text)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (vm.emailCheckStatus == CheckStatus.available)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '사용할 수 있는 이메일입니다.',
                            style: TextStyle(
                              color: Color(0xFF18745B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      MovieLogTextFormField(
                        key: const Key('passwordField'),
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: '비밀번호',
                        hint: '8자 이상 입력해 주세요',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해 주세요.';
                          }
                          if (value.length < 8) return '비밀번호는 8자 이상 입력해 주세요.';
                          return null;
                        },
                        onChanged: vm.onPasswordChanged,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 14),
                      _TermsAgreement(
                        value: vm.agreedToTerms,
                        onChanged: (value) => vm.onTermsChanged(value ?? false),
                      ),
                      const SizedBox(height: 24),
                      MovieLogButton(
                        key: const Key('signUpButton'),
                        label: '가입하기',
                        width: double.infinity,
                        onPressed: vm.canSubmit ? _submit : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '학습용 화면입니다. 계정 생성 없이 홈으로 이동합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7B7786),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_movies_rounded,
              color: Color(0xFF6C5CE7),
              size: 30,
            ),
            SizedBox(width: 8),
            Text(
              'MovieLog',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SizedBox(height: 30),
        Text(
          '반가워요!',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
          '나만의 영화 기록을 시작해 볼까요?',
          style: TextStyle(fontSize: 16, color: Color(0xFF6F6B78)),
        ),
      ],
    );
  }
}

class MovieLogTextFormField extends StatelessWidget {
  const MovieLogTextFormField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    required this.onChanged,
    required this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      forceErrorText: errorText,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorMaxLines: 3,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            key: const Key('termsCheckbox'),
            value: value,
            onChanged: onChanged,
          ),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '[필수] ',
                    style: TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '서비스 이용약관 및 개인정보 처리방침에 동의합니다.'),
                ],
              ),
              style: TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
