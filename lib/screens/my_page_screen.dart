import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          TextButton(onPressed: auth.logout, child: const Text('로그아웃')),
        ],
      ),
      body: auth.memberStatus == MemberLoadStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : auth.memberStatus == MemberLoadStatus.error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(auth.message ?? '내 정보를 불러오지 못했어요.'),
                  TextButton(
                    onPressed: () => auth.loadMember(force: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const CircleAvatar(
                  radius: 36,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  member?.nickname ?? '내 정보 확인 중',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(member?.email ?? ''),
                if (member != null)
                  Text(
                    '${member.createdAt.year}.${member.createdAt.month.toString().padLeft(2, '0')}.${member.createdAt.day.toString().padLeft(2, '0')} 가입',
                  ),
                TextButton(
                  onPressed: member == null
                      ? null
                      : () => context.push('/my/profile/edit'),
                  child: const Text('프로필 수정'),
                ),
                Card(
                  child: ListTile(
                    key: const Key('myRatingsTile'),
                    title: const Text('내가 등록한 평점'),
                    subtitle: const Text('현재 로그인 세션에서 생성한 기록'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/my/ratings'),
                  ),
                ),
              ],
            ),
    );
  }
}
