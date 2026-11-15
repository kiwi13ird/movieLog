import 'package:flutter/foundation.dart';

import '../data/models/sign_up_models.dart';

/// In-memory learning identity, not authentication; never stores a password.
class LearningMemberSession extends ChangeNotifier {
  SignUpResult? _member;
  int? get memberId => _member?.memberId;
  String? get nickname => _member?.nickname;
  void setMember(SignUpResult member) {
    if (member.memberId < 1) throw ArgumentError('유효한 회원 ID가 필요합니다.');
    _member = member;
    notifyListeners();
  }

  void clear() {
    _member = null;
    notifyListeners();
  }
}
