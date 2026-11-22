class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email, password;
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});
  final String nickname, accessToken;
  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    nickname: json['nickname'] as String,
    accessToken: json['accessToken'] as String,
  );
}
