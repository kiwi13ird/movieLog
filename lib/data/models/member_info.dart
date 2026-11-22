class MemberInfo {
  MemberInfo.fromJson(Map<String, dynamic> json)
    : email = json['email'] as String,
      nickname = json['nickname'] as String,
      createdAt = DateTime.parse(json['createdAt'] as String);
  final String email, nickname;
  final DateTime createdAt;
}
