import 'package:flutter/material.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('영화를 불러오는 중이에요.'),
      ],
    ),
  );
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('조건에 맞는 영화가 없습니다.'));
}

class MovieListError extends StatelessWidget {
  const MovieListError({
    required this.onRetry,
    this.isTimeout = false,
    super.key,
  });
  final VoidCallback onRetry;
  final bool isTimeout;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 40),
        const SizedBox(height: 12),
        Text(isTimeout ? '불러오는 시간이 너무 오래 걸려요.' : '영화를 불러오지 못했습니다.'),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}
