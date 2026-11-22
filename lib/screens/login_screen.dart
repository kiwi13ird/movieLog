import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.initialEmail, super.key});
  final String? initialEmail;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _prefs = SharedPreferencesAsync();
  bool _remember = false;
  late AuthViewModel _auth;
  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail ?? '';
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_expired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _expired());
    _restoreEmail();
  }

  Future<void> _restoreEmail() async {
    try {
      final email = await _prefs.getString('movielog.remembered_email');
      if (mounted && _email.text.isEmpty && email != null) {
        setState(() {
          _email.text = email;
          _remember = true;
        });
      }
    } catch (_) {
      /* Email persistence is optional. */
    }
  }

  void _expired() {
    if (!mounted || !_auth.consumeSessionExpired()) return;
    void show() {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
        );
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      show();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => show());
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final password = _password.text;
    _password.clear();
    await _auth.login(email, password);
    try {
      if (_remember) {
        await _prefs.setString('movielog.remembered_email', email);
      } else {
        await _prefs.remove('movielog.remembered_email');
      }
    } catch (_) {
      /* Authentication does not depend on remembering email. */
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_expired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final busy =
        auth.status == AuthStatus.authenticating ||
        auth.storageCleanupInProgress;
    return Scaffold(
      appBar: AppBar(title: const Text('MovieLog 로그인')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.movie_outlined, size: 72),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                    validator: (v) =>
                        v != null && v.contains('@') ? null : '이메일을 확인해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !busy,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    validator: (v) =>
                        v == null || v.isEmpty ? '비밀번호를 입력해 주세요.' : null,
                  ),
                  CheckboxListTile(
                    title: const Text('이메일 저장'),
                    value: _remember,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => _remember = v!),
                  ),
                  if (auth.message != null)
                    Text(
                      auth.message!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  MovieLogButton(
                    label: '로그인',
                    isLoading: busy,
                    onPressed: busy ? null : _login,
                  ),
                  TextButton(
                    onPressed: busy ? null : () => context.push('/register'),
                    child: const Text('회원가입'),
                  ),
                  if (auth.message?.contains('삭제') == true)
                    TextButton(
                      onPressed: busy ? null : auth.logout,
                      child: const Text('로그아웃 다시 시도'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionSplashScreen extends StatelessWidget {
  const SessionSplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                children: [
                  SizedBox(height: 32),
                  Text('FLUTTER 8주차'),
                  SizedBox(height: 64),
                  Icon(
                    Icons.movie_filter_rounded,
                    size: 84,
                    color: Color(0xFF6C5CE7),
                  ),
                  SizedBox(height: 32),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (auth.status == AuthStatus.retryRequired)
                Column(
                  children: [
                    Text(auth.message ?? '세션 확인 실패'),
                    MovieLogButton(
                      label: '다시 시도',
                      onPressed: auth.restoreSession,
                    ),
                  ],
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
