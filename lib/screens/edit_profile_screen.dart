import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/api_failure.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nickname = TextEditingController(
    text: context.read<AuthViewModel>().member?.nickname,
  );
  final _form = GlobalKey<FormState>();
  bool _saving = false, _leaving = false;
  String? _error;
  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving) return;
    final dirty =
        _nickname.text.trim() != context.read<AuthViewModel>().member?.nickname;
    final discard =
        !dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('변경 내용을 취소할까요?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('계속 수정'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('나가기'),
                  ),
                ],
              ),
            ) ==
            true;
    if (mounted && discard) {
      setState(() => _leaving = true);
      context.go('/my');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    try {
      await auth.updateNickname(_nickname.text.trim());
      if (!mounted || !auth.isCurrent(version)) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필을 저장했어요.')));
      setState(() => _leaving = true);
      context.go('/my');
    } catch (e) {
      if (!mounted || !auth.isCurrent(version)) return;
      final failure = ApiFailure.from(e);
      if (failure.code == 'MEMBER409_1' || failure.code == 'COMMON400') {
        setState(() => _error = failure.message);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 수정'),
          leading: BackButton(onPressed: _saving ? null : _leave),
        ),
        body: auth.member == null
            ? Center(
                child: MovieLogButton(
                  label: '내 정보 다시 불러오기',
                  onPressed: () => auth.loadMember(force: true),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: auth.member!.email,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: '이메일'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nickname,
                        enabled: !_saving,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: InputDecoration(
                          labelText: '닉네임',
                          errorText: _error,
                        ),
                        validator: (v) =>
                            v == null ||
                                v.trim().runes.length < 2 ||
                                v.trim().runes.length > 12
                            ? '닉네임은 2~12자로 입력해 주세요.'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      MovieLogButton(
                        label: '저장',
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
