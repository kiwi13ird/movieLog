import 'package:flutter/material.dart';

import '../widgets/movielog_button.dart';

/// Debug-only route for reproducible button-state/width submission evidence.
class ButtonShowcaseScreen extends StatelessWidget {
  const ButtonShowcaseScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('공용 버튼 비교')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '너비 비교',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('null · 내용에 맞는 너비'),
        const SizedBox(height: 8),
        Row(
          children: [
            MovieLogButton(
              key: const Key('buttonWidthNull'),
              label: '중복 확인',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('double.infinity · 부모의 최대 너비'),
        const SizedBox(height: 8),
        MovieLogButton(
          key: const Key('buttonWidthFull'),
          label: '가입하기',
          width: double.infinity,
          onPressed: () {},
        ),
        const SizedBox(height: 24),
        const Text('고정값 · 160'),
        const SizedBox(height: 8),
        Row(
          children: [
            MovieLogButton(
              key: const Key('buttonWidthFixed'),
              label: '고정 너비',
              width: 160,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          '상태 비교',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            MovieLogButton(label: '기본', onPressed: () {}),
            MovieLogButton(label: '통신 중', isLoading: true, onPressed: () {}),
            const MovieLogButton(label: '비활성', onPressed: null),
          ],
        ),
      ],
    ),
  );
}
