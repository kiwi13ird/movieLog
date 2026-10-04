import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.local_movies_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'MovieLog',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                '좋아하는 영화를 기록하고\n나만의 리스트를 만들어 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6F6B78),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const Key('startButton'),
                  onPressed: () => context.pushReplacement('/signup'),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
