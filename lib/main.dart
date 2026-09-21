import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C5CE7);
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE4E1EC)),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: roundedBorder,
          enabledBorder: roundedBorder,
          focusedBorder: roundedBorder.copyWith(
            borderSide: const BorderSide(color: purple, width: 2),
          ),
          errorBorder: roundedBorder.copyWith(
            borderSide: const BorderSide(color: Color(0xFFE5484D)),
          ),
          focusedErrorBorder: roundedBorder.copyWith(
            borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2),
          ),
        ),
      ),
      home: const MissionHomeScreen(),
    );
  }
}

class MissionHomeScreen extends StatefulWidget {
  const MissionHomeScreen({super.key});

  @override
  State<MissionHomeScreen> createState() => _MissionHomeScreenState();
}

class _MissionHomeScreenState extends State<MissionHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [SignUpScreen(), RatingScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add),
            label: '회원가입',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: '평점 기록',
          ),
        ],
      ),
    );
  }
}

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

  bool get _canSubmit {
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return _nicknameController.text.trim().length >= 2 &&
        emailPattern.hasMatch(_emailController.text.trim()) &&
        _passwordController.text.length >= 8 &&
        _agreedToTerms;
  }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nicknameController.text.trim()}님, 가입 준비가 완료됐어요!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 24,
              32,
              isWide ? 40 : 24,
              32,
            ),
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
                          if (nickname.isEmpty) {
                            return '닉네임을 입력해 주세요.';
                          }
                          if (nickname.length < 2) {
                            return '닉네임은 두 글자 이상 입력해 주세요.';
                          }
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
                          if (value.length < 8) {
                            return '비밀번호는 8자 이상 입력해 주세요.';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
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
          );
        },
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

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    final hasRating = _rating > 0;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '오늘의 영화',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '감상한 영화에 별점을 남겨보세요.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6F6B78)),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 128,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.movie_creation_outlined,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '라라랜드',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'La La Land · 2016',
                        style: TextStyle(color: Color(0xFF7B7786)),
                      ),
                      const SizedBox(height: 28),
                      KeyedSubtree(
                        key: const Key('ratingBar'),
                        child: RatingBar.builder(
                          initialRating: _rating,
                          minRating: 0.5,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 46,
                          glow: false,
                          unratedColor: const Color(0xFFE1DFE8),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                          ),
                          onRatingUpdate: (rating) =>
                              setState(() => _rating = rating),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasRating ? '$_rating / 5.0' : '별을 눌러 평점을 선택해 주세요',
                        style: TextStyle(
                          color: hasRating
                              ? const Color(0xFF6C5CE7)
                              : const Color(0xFF7B7786),
                          fontWeight: hasRating
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          key: const Key('saveRatingButton'),
                          onPressed: hasRating
                              ? () => ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                      SnackBar(
                                        content: Text('평점 $_rating점을 저장했어요!'),
                                      ),
                                    )
                              : null,
                          child: const Text('평점 저장하기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
