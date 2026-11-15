import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마이페이지',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 28),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person_rounded, size: 34),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '무비로그 회원',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '나만의 영화 기록',
                          style: TextStyle(color: Color(0xFF6F6B78)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                key: const Key('myRatingsTile'),
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('내가 등록한 평점'),
                subtitle: const Text('학습용 회원 1의 공개 데이터'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/ratings'),
              ),
            ),
            if (kDebugMode)
              TextButton(
                key: const Key('buttonShowcaseLink'),
                onPressed: () => context.push('/button-showcase'),
                child: const Text('공용 버튼 비교'),
              ),
          ],
        ),
      ),
    );
  }
}
