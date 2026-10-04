import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms;

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    MovieLogTextFormField(
                      key: const Key('nicknameField'),
                      controller: _nicknameController,
                      focusNode: _nicknameFocusNode,
                      label: '닉네임',
                      hint: '두 글자 이상 입력해 주세요',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final nickname = value?.trim() ?? '';
                        if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
                        if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해 주세요.';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 18),
                    MovieLogTextFormField(
                      key: const Key('emailField'),
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      label: '이메일',
                      hint: 'movielog@example.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return '이메일을 입력해 주세요.';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(email)) {
                          return '올바른 이메일 형식으로 입력해 주세요.';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
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
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 14),
                    _TermsAgreement(
                      value: _agreedToTerms,
                      onChanged: (value) =>
                          setState(() => _agreedToTerms = value ?? false),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        key: const Key('signUpButton'),
                        onPressed: _canSubmit ? _submit : null,
                        child: const Text(
                          '가입하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '입력한 정보는 연습 화면 안에서만 사용됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7B7786), fontSize: 12),
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
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
